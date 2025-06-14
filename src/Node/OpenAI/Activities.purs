module Node.OpenAI.Activities 
  ( countWords
  , frequentWords
  , sentiment
  ) where

import Prelude (($), (<>), bind, discard, pure)
import Data.Argonaut as Argonaut
import Data.Maybe (Maybe(Just))
import Temporal.Exchange (ExchangeI, ExchangeO)
import Temporal.Node.Activity (useInput, output, liftOperation)
import Temporal.Node.Activity.Unsafe (unsafeRunActivity)
import Temporal.Node.Platform (liftLogger, performEffect, awaitAff, lookupEnv)
import Temporal.Logger (info)
import Temporal.Logger.Argonaut (decode') 
import OpenAI (createClient, createCompletion) as OpenAI
import Promise (Promise)

ai :: String -> String -> String -> _
ai system prompt input = do
 apiKey <- lookupEnv "OPENAI_API_KEY"
 client <- performEffect $ OpenAI.createClient apiKey
 let message = "SYSTEM: You are an AI-generated function that takes a String INPUT" <> system  <> "."
               <> "\nPROMPT: " <> prompt
               <> "\nINPUT: " <> input
 liftLogger $ info $ "AI request:\n" <> message
 ret <- awaitAff $ OpenAI.createCompletion client "gpt-4o" message
 liftLogger $ info $ "AI response:\n" <> ret
 pure ret

aiJson system p i = liftOperation do
  out <- ai (system <> " and returns a single valid JSON value. The value should match the kind of information requested in the PROMPT. Do not include any keys, labels, or explanations—only return the raw JSON value (such as a number, string, boolean, or array)") p i
  liftLogger $ decode' out

countWords :: ExchangeI -> Promise ExchangeO
countWords i = unsafeRunActivity @String @Int do
  input <- useInput i
  let prompt = "The number of words from the INPUT."
  out <- aiJson "" prompt input
  output out

frequentWords :: ExchangeI -> Promise ExchangeO
frequentWords i = unsafeRunActivity @String @(Array String) do
  input <- useInput i
  let prompt = "The 5 most frequent words from the INPUT (ignoring stopwords, if possible)."
  out <- aiJson "" prompt input
  output out

sentiment :: ExchangeI -> Promise ExchangeO
sentiment i = unsafeRunActivity @String @String do
  input <- useInput i
  let prompt = "A summary of the sentiment of the INPUT."
  out <- aiJson "" prompt input
  output out
