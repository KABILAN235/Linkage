import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import "./types.ts";



Deno.serve(async (req)=>{
    try {
      const body = await req.arrayBuffer();
      const fileName = `file-${Date.now()}.pdf`;

      // Save the file to Supabase Storage
      const response = await fetch("https://your-supabase-url.supabase.co/storage/v1/object/bucket-name/" + fileName, {
        method: "PUT",
        headers: {
          "Authorization": `Bearer your-supabase-service-role-key`,
          "Content-Type": "application/pdf",
        },
        body,
      });

      if (response.ok) {
        return new Response(JSON.stringify({ message: "File saved successfully", fileName }), { status: 200 });
      } else {
        const error = await response.text();
        return new Response(JSON.stringify({ error }), { status: response.status });
      }
    } catch (error) {
      return new Response(JSON.stringify({ error: "Something Bad Happened"}), { status: 500 });
    }
}); 