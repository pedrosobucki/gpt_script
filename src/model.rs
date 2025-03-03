use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use crate::chat::Message;
use std::error::Error;
use clap::ValueEnum;
use crate::args::CompletionArgs;
use crate::config::Config;
use reqwest::{Response, StatusCode};

#[derive(Serialize, Deserialize, Debug, Clone, ValueEnum)]
#[clap(rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum Provider {
    OpenAI,
    Anthropic,
    XAI,
}

pub trait ModelImpl {
    async fn complete(&self, messages: &mut Vec<Message>) -> String;
    async fn completion_request(&self, messages: &mut Vec<Message>) -> Result<Response, Box<dyn Error>>;
}

pub enum Model {
    Gpt(Gpt),
    Claude(Claude),
    Grok(Grok),
}

impl ModelImpl for Model {
    async fn completion_request(&self, messages: &mut Vec<Message>) -> Result<Response, Box<dyn Error>> {
        match &self {
            Model::Gpt(model) => model.completion_request(messages).await,
            Model::Claude(model) => model.completion_request(messages).await,
            Model::Grok(model) => model.completion_request(messages).await,
        }
    }

    async fn complete(&self, messages: &mut Vec<Message>) -> String {
        match &self {
            Model::Gpt(model) => model.complete(messages).await,
            Model::Claude(model) => model.complete(messages).await,
            Model::Grok(model) => model.complete(messages).await,
        }
    }
}

#[derive(Debug)]
pub struct Gpt {
    pub name: String,
    pub provider: Provider,
    pub max_tokens: u32,
    pub temperature: f32,
    pub api_key: String,
}

impl ModelImpl for Gpt {
    async fn completion_request(&self, messages: &mut Vec<Message>) -> Result<Response, Box<dyn Error>> {
        // Create a client
        let client = reqwest::Client::new();

        // Define the request payload
        let request_body = json!({
            "model": self.name,
            "messages": messages,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
        });

        // Send the request
        let response = client
            .post("https://api.openai.com/v1/chat/completions")
            .header("Authorization", format!("Bearer {}", self.api_key))
            .json(&request_body)
            .send()
            .await?;

        Ok(response)
    }

    async fn complete(&self, messages: &mut Vec<Message>) -> String {
        let response: Response = self.completion_request(messages).await.expect("Failed to get response from OpenAI API!");
        let status: StatusCode = response.status();
        // dbg!(&response);
        let json: Value = response.json().await.expect("Failed to decode response JSON");
        // dbg!(&json);

        if !status.is_success() {
            let pretty_json: String = serde_json::to_string_pretty(&json).expect("failed to pretty print JSON");
            return format!("\x1b[31mX\x1b[0m Request error code {}:\n{}", status, pretty_json);
        }

        let new_message: Message = json["choices"][0]["message"].clone().into();
        let answer: String = new_message.content.clone();

        // under user message, add assistant message
        messages.push(new_message);

        answer
    }
}


#[derive(Debug)]
pub struct Claude {
    pub name: String,
    pub provider: Provider,
    pub max_tokens: u32,
    pub temperature: f32,
    pub api_key: String,
}

impl ModelImpl for Claude {
    async fn completion_request(&self, messages: &mut Vec<Message>) -> Result<Response, Box<dyn Error>> {
        // Create a client
        let client = reqwest::Client::new();

        let mut msgs_clone: Vec<Message> = messages.clone();
        let system:String = msgs_clone[0].content.clone();
        msgs_clone.remove(0);

        // Define the request payload
        let request_body = json!({
            "model": self.name,
            "messages": msgs_clone,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
            "system": system,
        });

        // Send the request
        let response = client
            .post("https://api.anthropic.com/v1/messages")
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", "2023-06-01")
            .header("content-type", "application/json")
            .json(&request_body)
            .send()
            .await?;

        Ok(response)
    }

    async fn complete(&self, messages: &mut Vec<Message>) -> String {
        let response: Response = self.completion_request(messages).await.expect("Failed to get response from OpenAI API!");
        let status: StatusCode = response.status();
        // dbg!(&response);
        let json: Value = response.json().await.expect("Failed to decode response JSON");
        // dbg!(&json);

        if !status.is_success() {
            let pretty_json: String = serde_json::to_string_pretty(&json).expect("failed to pretty print JSON");
            return format!("\x1b[31mX\x1b[0m Request error code {}:\n{}", status, pretty_json);
        }

        json.as_object().expect("Failed to convert JSON to object").get("content");
        let content = json.get("content").expect("failed")[0].get("text").and_then(|v| v.as_str()).expect("failed").to_string();

        let new_message: Message = Message {
            role: "assistant".to_string(),
            content,
        };

        let answer: String = new_message.content.clone();

        // under user message, add assistant message
        messages.push(new_message);

        answer
    }
}

#[derive(Debug)]
pub struct Grok {
    pub name: String,
    pub provider: Provider,
    pub max_tokens: u32,
    pub temperature: f32,
    pub api_key: String,
}

impl ModelImpl for Grok {
    async fn completion_request(&self, messages: &mut Vec<Message>) -> Result<Response, Box<dyn Error>> {
        // Create a client
        let client = reqwest::Client::new();

        // Define the request payload
        let request_body = json!({
            "model": self.name,
            "messages": messages,
            "temperature": self.temperature,
            "max_tokens": self.max_tokens,
        });

        // Send the request
        let response = client
            .post("https://api.x.ai/v1/chat/completions")
            .header("Authorization", format!("Bearer {}", self.api_key))
            .json(&request_body)
            .send()
            .await?;

        Ok(response)
    }

    async fn complete(&self, messages: &mut Vec<Message>) -> String {
        let response: Response = self.completion_request(messages).await.expect("Failed to get response from OpenAI API!");
        let status: StatusCode = response.status();
        // dbg!(&response);
        let json: Value = response.json().await.expect("Failed to decode response JSON");
        // dbg!(&json);

        if !status.is_success() {
            let pretty_json: String = serde_json::to_string_pretty(&json).expect("failed to pretty print JSON");
            return format!("\x1b[31mX\x1b[0m Request error code {}:\n{}", status, pretty_json);
        }

        let new_message: Message = json["choices"][0]["message"].clone().into();
        let answer: String = new_message.content.clone();

        // under user message, add assistant message
        messages.push(new_message);

        answer
    }
}

pub fn build_model(config: &Config, args: &CompletionArgs) -> Model {
    match args.provider {
        Provider::OpenAI => Model::Gpt(Gpt {
            name: args.model.clone(),
            provider: args.provider.clone(),
            max_tokens: args.tokens,
            temperature: args.temperature,
            api_key: config.openai_api_key.clone()
        }),
        Provider::Anthropic => Model::Claude(Claude {
            name: args.model.clone(),
            provider: args.provider.clone(),
            max_tokens: args.tokens,
            temperature: args.temperature,
            api_key: config.anthropic_api_key.clone()
        }),
        Provider::XAI => Model::Grok(Grok {
            name: args.model.clone(),
            provider: args.provider.clone(),
            max_tokens: args.tokens,
            temperature: args.temperature,
            api_key: config.xai_api_key.clone()
        }),
    }
}