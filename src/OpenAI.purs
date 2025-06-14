module OpenAI
  ( Client
  , createClient
  , createCompletion
  ) where

import Prelude ((<<<))
import Effect (Effect)
import Effect.Uncurried (EffectFn2, EffectFn3, runEffectFn2, runEffectFn3)
import Effect.Aff (Aff)
import Promise.Aff (Promise, toAffE)

type APIKey = String

foreign import data OpenAICtor :: Type

foreign import openAICtor :: OpenAICtor

foreign import data Client :: Type

foreign import createClientImpl :: EffectFn2 OpenAICtor APIKey Client

createClient :: APIKey -> Effect Client
createClient = runEffectFn2 createClientImpl openAICtor

type Model = String
type Input = String
type Completion = String

foreign import createCompletionImpl :: EffectFn3 Client Model Input (Promise Completion)

createCompletion :: Client -> Model -> Input -> Aff Completion
createCompletion c m = toAffE <<< runEffectFn3 createCompletionImpl c m
