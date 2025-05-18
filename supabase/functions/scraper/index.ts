import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2'
import "./types.ts";



Deno.serve(async (req)=>{
    try {
       const supabase = createClient(
            Deno.env.get('SUPABASE_URL') ?? '',
            Deno.env.get('SUPABASE_ANON_KEY') ?? '',
            { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
          );

      const pdfBody = await req.arrayBuffer();
      const fileName = `file-${Date.now()}.pdf`;
      
      const data = await supabase.storage.from("linkage-bucket").upload(fileName,pdfBody);

        return new Response(JSON.stringify({ message: "File saved successfully", fileName }), { status: 200 });
      }
     catch (_error) {
      return new Response(JSON.stringify({ error: "Something Bad Happened"}), { status: 500 });
    }
}); 