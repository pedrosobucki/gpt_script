use crate::config::Config;
use crate::model::{self, Model, ModelImpl};
use crate::chat::Message;
use crate::session::Session;
use crate::args::CompletionArgs;

pub async fn ask(args: CompletionArgs, session: &mut Session, config: Config) {
  let model: Model = model::build_model(&config, &args);
  let mut msg: String = args.prompt.clone();

  if args.raw {
    msg.push_str("\n<INSTRUCTION>This specific response should only be code, without explanations, markdown formating or anything other than the code itself.</INSTRUCTION>");
  }

  let user_input: Message = Message {role: String::from("user"), content: msg};

  // pushes user input to chat history
  session.messages.push(user_input);

  // dbg!(&config);
  // dbg!(&model);
  // dbg!(&session);

  let answer: String = model.complete(&mut session.messages).await;
  session.save();
  println!("{}", answer);
  // dbg!(&session);
}