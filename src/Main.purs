module Main (main) where

import Debug
import Prelude
  ( Unit
  , ($)
  , (<>)
  , bind
  , discard
  , show
  )
import Data.String
  ( Pattern(Pattern)
  , Replacement(Replacement)
  )
import Data.String.Common (replace)
import Effect.Aff (Aff, launchAff_)
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Node.EsModule (resolve)
import Node.Activities (createActivities)
import Temporal.Client
  ( WorkflowHandle
  , Connection
  , defaultConnectionOptions
  , connect
  , startWorkflow
  , result
  , close
  , createClient
  , defaultClientOptions
  )
import Temporal.Node.Worker (createWorker, runWorker, bundleWorkflowCode)
import HTTPurple
  ( class Generic
  , RouteDuplex'
  , ServerM
  , Method(Post)
  , (/)
  , serve
  , mkRoute
  , noContent
  , notFound
  , fromJson
  , noArgs
  , usingCont
  )
import HTTPurple.Json.Argonaut (jsonDecoder)

taskQueue :: String
taskQueue = "analyze-text"

startWorker :: Aff Unit
startWorker = do
  workflowsPath <- liftEffect $ resolve "../Workflows/index.js"
  workflowBundle <-
    bundleWorkflowCode
      -- TODO use Node.URL href in workflowsPath
      { workflowsPath: replace
          (Pattern "file://")
          (Replacement "")
          workflowsPath
      }
  worker <-
    createWorker
      { taskQueue
      , workflowBundle
      , activities: createActivities
      }
  runWorker worker

getResults :: WorkflowHandle -> Connection -> Aff Unit
getResults wfHandler con = do
  _ <- result wfHandler
  liftEffect $ log "closing"
  close con
  liftEffect $ log "done"

runTemporal :: String -> Effect Unit
runTemporal text =
  launchAff_ do
    con <- connect defaultConnectionOptions
    client <- liftEffect $ createClient defaultClientOptions
    wfHandler <-
      startWorkflow client "analyzeText"
        { taskQueue
        , workflowId: "analyze-text-1"
        , args: [ text ]
        }
    (startWorker <> getResults wfHandler con)

data Route = AnalyzeText

derive instance Generic Route _

route :: RouteDuplex' Route
route = mkRoute
  { "AnalyzeText": "analyze-text" / noArgs
  }

type AnalyzeTextRequest = { "text" :: String }

main :: ServerM
main = serve { port: 8080 } { route, router }
  where
  router { route: AnalyzeText, method: Post, body } = usingCont do
    { "text": text } :: AnalyzeTextRequest <- fromJson jsonDecoder body
    liftEffect $ runTemporal text
    noContent
  router _ = notFound
