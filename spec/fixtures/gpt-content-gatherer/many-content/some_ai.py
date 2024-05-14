# Write a system to talk to ChatGPT using Python

import openai

openai.api_key = "sk-1234567890abcdef1234567890abcdef"
openai.ChatCompletion.create(
  model="gpt-3.5-turbo",
  messages=[
    {"role": "system", "content": "Hello, how are you?"},
    {"role": "user", "content": "I'm good, thanks. How are you?"},
  ]
)