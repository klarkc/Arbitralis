module Workflows
  ( ActivitiesI_
  , ActivitiesI
  , AnalyzeTextResult
  , analyzeText
  ) where

import Prelude
  ( ($)
  , bind
  )
import Promise (Promise)
import Data.Maybe (Maybe(Just))
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
  )

type ActivitiesI = ActivitiesI_ (ExchangeI -> Promise ExchangeO)

type AnalyzeTextResult =
  { textWords :: Int
  }

analyzeText :: ExchangeI -> Promise ExchangeO
analyzeText i = unsafeRunWorkflow @ActivitiesJson @String @(Maybe AnalyzeTextResult) do
  act <- proxyActivities defaultProxyOptions
  text <- useInput i
  textWords <- runActivity act.countWords text
  output $ Just { textWords }
