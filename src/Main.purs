module Main (main) where

import Prelude
  ( ($)
  , (<<<)
  , (<$>)
  , (<*>)
  , bind
  , discard
  , pure
  , void
  )
import Control.Parallel (sequential, parallel)
import Data.Argonaut as Argonaut
import Data.String
  ( Pattern(Pattern)
  , Replacement(Replacement)
  )
import Data.String.Common (replace)
import Effect.Aff (Aff, forkAff)
import Effect.Aff.Class (class MonadAff, liftAff)
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
import Temporal.Node.Worker (Worker, createWorker, runWorker, shutdownWorker, bundleWorkflowCode)
import HTTPurple as HTTP
import HTTPurple
  ( class Generic
  , Method(Post)
  , (/)
  )
import HTTPurple.Json.Argonaut (jsonDecoder, jsonEncoder) as HTTP.Argonaut
import Workflows (AnalyzeTextResult)

taskQueue :: String
taskQueue = "analyze-text"

startWorker :: Aff Worker
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
  void $ forkAff $ runWorker worker
  pure worker

getResults :: forall a. WorkflowHandle -> Connection -> Aff a
getResults wfHandler con = do
  res <- result wfHandler
  close con
  pure res

runTemporal :: forall a. String -> Aff a
runTemporal text = do
  let workflowId = "analyzeText"
  con <- connect defaultConnectionOptions
  client <- liftEffect $ createClient defaultClientOptions
  wfHandler <-
    startWorkflow client workflowId
      { taskQueue
      , workflowId
      , args: [ text ]
      }
  { result, worker } <- sequential
    $ { worker: _, result: _ }
        <$> parallel startWorker
        <*> parallel (getResults wfHandler con)
  liftEffect $ shutdownWorker worker
  pure result

data Route = AnalyzeText

derive instance Generic Route _

route :: HTTP.RouteDuplex' Route
route = HTTP.mkRoute
  { "AnalyzeText": "analyze-text" / HTTP.noArgs
  }

type AnalyzeTextRequest = { "text" :: String }
type AnalyzeTextResponse = AnalyzeTextResult

main :: HTTP.ServerM
main = HTTP.serve { port: 8080 } { route, router }
  where
  ok' :: forall a m. MonadAff m => Argonaut.EncodeJson a => a -> m _
  ok' = HTTP.ok <<< HTTP.toJson HTTP.Argonaut.jsonEncoder
  router { route: AnalyzeText, method: Post, body } = HTTP.usingCont do
    { "text": text } :: AnalyzeTextRequest <- HTTP.fromJson HTTP.Argonaut.jsonDecoder body
    res :: AnalyzeTextResponse <- liftAff $ runTemporal text
    ok' res
  router _ = HTTP.notFound
