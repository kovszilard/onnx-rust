use ort::{inputs, session::Session, value::Tensor};
use tokenizers::Tokenizer;

fn main() -> Result<(), Box<dyn std::error::Error + Send + Sync>> {
    let tokenizer = Tokenizer::from_file("distilbert_sst2_onnx/tokenizer.json")?;
    let mut session = Session::builder()?.commit_from_file("distilbert_sst2_onnx/model.onnx")?;

    let examples = ["I love this movie!", "This was a complete waste of time."];

    for text in examples {
        let encoding = tokenizer.encode(text, true)?;
        let ids: Vec<i64> = encoding.get_ids().iter().map(|&x| x as i64).collect();
        let mask: Vec<i64> = encoding
            .get_attention_mask()
            .iter()
            .map(|&x| x as i64)
            .collect();
        let shape = [1, ids.len()];

        let outputs = session.run(inputs![
            "input_ids" => Tensor::from_array((shape, ids))?,
            "attention_mask" => Tensor::from_array((shape, mask))?,
        ])?;

        // logits: [1, 2] = [negative, positive]
        let (_, logits) = outputs["logits"].try_extract_tensor::<f32>()?;
        let p_pos = 1.0 / (1.0 + (logits[0] - logits[1]).exp());
        let label = if p_pos > 0.5 { "POSITIVE" } else { "NEGATIVE" };

        println!("{label} ({p_pos:.4})  {text}");
    }

    Ok(())
}
