import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2'
import OpenAI from 'jsr:@openai/openai';
import "./types.ts";



Deno.serve(async (req) => {
  try {
    const {queryUuid,pdfUrl,additionalPrompt} = await req.json();

    const client = new OpenAI({
      apiKey: Deno.env.get('OPENAI_API_KEY'),
    });

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )


    const { data ,error } = await supabase.storage
      .from("linkage-bucket")
      .download(pdfUrl);
    
    if (error) throw error

    const pdfTempPath = `/tmp/${queryUuid}.pdf`;
    await Deno.writeFile(pdfTempPath, new Uint8Array(await data.arrayBuffer()));

    const fileContent = await Deno.readFile(pdfTempPath);
    const blob = new Blob([fileContent], { type: "application/pdf" });

    const formData = new FormData();
    formData.append("file", blob, `${queryUuid}.pdf`);
    formData.append("purpose", "assistants");

    const fileUploadResponse = await fetch("https://api.openai.com/v1/files", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: formData,
    });

    const fileResponse = await fileUploadResponse.json();

    const response = await client.responses.create({
      model: "gpt-4.1",
      input: [
        {
          "role": "system",
          "content": [
            {
              "type": "input_text",
              "text": "Extract data from a PDF document and return it in a JSON format with two fields: \"Columns\" and \"Data\". The \"Columns\" should reflect specific data categories or labels requested by the user, while \"Data\" should include the extracted information corresponding to those columns. The PDF should be fully read\n\nAdditional instructions given by the user about which columns are relevant should guide how the data is categorized and labeled.\n\n# Steps\n\n1. **Understanding User Instructions**: Carefully read any optional user instructions regarding column requirements to determine what specific data should be extracted and how it should be organized.\n   \n2. **PDF Data Extraction**: Process the PDF to extract text and relevant data. \n\n3. **Data Categorization**: Identify and categorize the extracted data based on the user's column instructions.\n\n4. **JSON Structuring**: Organize the data into a JSON structure with \"Columns\" reflecting the user’s specified categories and \"Data\" containing corresponding extracted details.\n\n# Output Format\n\nOutput should be in the following JSON format:\n\n```json\n{\n  \"Columns\": [ /* array of column names as specified or inferred from the data */ ],\n  \"Data\": [ /* array of data objects corresponding to the specified columns */ ]\n}\n```\n\n# Examples\n\n**Example Input**: \n- (A sample PDF and user instructions specifying columns like \"Title\", \"Date\", \"Content\")\n\n**Example Output**: \n```json\n{\n  \"Columns\": [\"Title\", \"Date\", \"Content\"],\n  \"Data\": [\n    {\"Title\": \"Sample Title 1\", \"Date\": \"2023-05-10\", \"Content\": \"Sample content 1.\"},\n    {\"Title\": \"Sample Title 2\", \"Date\": \"2023-05-11\", \"Content\": \"Sample content 2.\"}\n  ]\n}\n```\n(Note: Real examples will depend on actual PDF content and user column criteria.)\n\n# Notes\n\n- User instructions may vary; ensure flexibility in understanding column specifications.\n- Data extraction accuracy is dependent on the PDF’s formatting and content clarity.\n- Handle diverse PDF structures and instructions effectively.\n- Make sure to read the entire pdf to extract all the datapoints"
            }
          ]
        },
        {
          role: "user",
          content: [
             {
                    type: "input_file",
                    file_id: fileResponse.id ,
              },
            {
              type: "input_text",
              text: additionalPrompt??"",
            },
          ],
        },
      ],
      text: {
        "format": {
          "type": "json_schema",
          "name": "pdf_extraction",
          "strict": false,
          "schema": {
            "type": "object",
            "properties": {},
            "required": []
          }
        }
      },
      reasoning: {},
      tools: [],
      temperature: 1,
      max_output_tokens: 32768,
      top_p: 1,
      store: true
    });

    const jsonResponse = JSON.parse(response.output_text)

    const columns = jsonResponse['Columns'];
    const datapoints = jsonResponse['Data'];

    let columnIds: { [key: string]: string } = {};

    for (const [index, columnName] of columns.entries()) {
      const { data: insertData, error: insertError } = await supabase
        .from('Column')
        .insert([
          {
            query_uuid: queryUuid,
            name: columnName,
            sort_idx: index,
          },
        ])
        .select("uuid")
        .single();

      if (insertError) throw insertError;
      if (!insertData) throw new Error("Failed to insert column or retrieve its UUID");

      columnIds[columnName] = insertData.uuid;
    }

    for (const [index, datapoint] of datapoints.entries()) {
      // Create a Record for this row of data
      const { data: recordInsertData, error: recordInsertError } = await supabase
        .from('Record')
        .insert([
          {
            query_uuid: queryUuid,
            sort_idx: index,
            // created_at will be set by default by the database
          },
        ])
        .select("uuid")
        .single();

      if (recordInsertError) throw recordInsertError;
      if (!recordInsertData) throw new Error("Failed to insert record or retrieve its UUID");
      
      const recordUuid = recordInsertData.uuid;

      // Prepare Datapoint entries for this Record
      const datapointEntries = Object.entries(datapoint).map(([columnName, value]) => {
        if (columnIds[columnName] === undefined) {
          // This case should ideally not happen if JSON response is consistent
          // Or handle as per your application's error strategy (e.g., skip, log, error)
          console.warn(`Column ID not found for column name: ${columnName}. Skipping this datapoint.`);
          return null; 
        }
        return {
          record_id: recordUuid,
          column_id: columnIds[columnName],
          data: String(value), // Ensure data is stored as a string
        };
      }).filter(entry => entry !== null); // Filter out any null entries if a column was skipped

      if (datapointEntries.length > 0) {
        const { error: datapointInsertError } = await supabase
          .from('Datapoint')
          .insert(datapointEntries as any); // Cast as any if TS complains about the filtered array type

        if (datapointInsertError) throw datapointInsertError;
      }
    }

    await supabase
      .from('Query')
      .update({ success: true })
      .eq('uuid', queryUuid);
    

    return new Response(
      JSON.stringify({ answer: jsonResponse }),
      { status: 200 }
    );
  } catch (_error) {
    return new Response(JSON.stringify({ error: _error }), { status: 500 });
  }
});