export { default as openAICtor } from "openai"

export function createClientImpl(openAICtor, apiKey) {
	return new openAICtor({ apiKey })
}

export function createCompletionImpl(client, model, input) {
	const messages = [{ role: "user", content: input }]
	return client.chat.completions
		.create({ model, messages })
		.then(c => c.choices[0].message.content)	
}

