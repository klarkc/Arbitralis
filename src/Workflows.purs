module Workflows
  ( ActivitiesI_
  , ActivitiesI
  , AnalyzeTextResult
  , analyzeText
  ) where

import Prelude
  ( bind
  )
import Promise (Promise)
import Temporal.Workflow
  ( ActivityJson
  , useInput
  , proxyActivities
  , defaultProxyOptions
  , output
  , runActivity
  )
import Temporal.Workflow.Unsafe (unsafeRunWorkflow)
import Temporal.Exchange (ExchangeI, ExchangeO)

type ActivitiesJson = ActivitiesI_ ActivityJson

type ActivitiesI_ :: forall k. k -> Row k
type ActivitiesI_ actFr =
  ( countWords :: actFr
  , frequentWords :: actFr
  , sentiment :: actFr
  )

type ActivitiesI = ActivitiesI_ (ExchangeI -> Promise ExchangeO)

type AnalyzeTextResult =
  { textWords :: Int
  , frequentWords :: Array String
  , sentiment :: String
  }

analyzeText :: ExchangeI -> Promise ExchangeO
analyzeText i = unsafeRunWorkflow @ActivitiesJson @String @AnalyzeTextResult do
  act <- proxyActivities defaultProxyOptions
  text <- useInput i
  textWords <- runActivity act.countWords text
  frequentWords <- runActivity act.frequentWords text
  sentiment <- runActivity act.sentiment text
  output { textWords
         , frequentWords
         , sentiment 
         }
