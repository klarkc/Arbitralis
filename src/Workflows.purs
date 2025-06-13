module Workflows
  ( ActivitiesI_
  , ActivitiesI
  , analyzeText
  ) where

import Prelude
  ( (==)
  , ($)
  , (<$>)
  , (>)
  , (&&)
  , (/=)
  , bind
  , discard
  , show
  , pure
  )
import Promise (Promise)
import Data.Maybe (Maybe(Just, Nothing))
import Data.Array (filter, length, head)
import Data.DateTime(DateTime(DateTime))
import Data.String (toUpper)
import Temporal.Workflow
  ( ActivityJson
  , useInput
  , proxyActivities
  , defaultProxyOptions
  , output
  , runActivity
  , fromMaybe
  , liftLogger
  , liftedMaybe
  )
import Temporal.Workflow.Unsafe (unsafeRunWorkflow)
import Temporal.Exchange (ISO(ISO), ExchangeI, ExchangeO)
import Temporal.Logger (info, warn, liftMaybe)

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
