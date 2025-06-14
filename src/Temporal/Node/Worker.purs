module Temporal.Node.Worker
  ( Worker
  , createWorker
  , runWorker
  , shutdownWorker
  , bundleWorkflowCode
  ) where

import Prelude
  ( (<<<)
  , ($)
  , Unit
  )
import Data.Function.Uncurried (Fn1, runFn1)
import Effect (Effect)
import Effect.Aff (Aff)
import Effect.Uncurried (EffectFn1, runEffectFn1)
import Promise.Aff (Promise, toAff)
import Foreign.Object (Object, fromHomogeneous)
import Type.Row.Homogeneous (class Homogeneous)

type WorkflowBundle =
  { code :: String
  }

type WorkerOptions :: forall k. (k -> Type) -> k -> Type
type WorkerOptions f a =
  { taskQueue :: String
  , activities :: f a
  , workflowBundle :: WorkflowBundle
  }

data WorkerCtor

data Worker

type BundleOptions =
  { workflowsPath :: String
  }

foreign import createWorkerImpl :: forall a. Fn1 (WorkerOptions Object a) (Promise Worker)

createWorker_ :: forall r a. Homogeneous r a => WorkerOptions Record r -> Promise Worker
createWorker_ rec =
  runFn1 createWorkerImpl
    $ rec
        { activities = fromHomogeneous $ rec.activities
        }

createWorker :: forall r a. Homogeneous r a => WorkerOptions Record r -> Aff Worker
createWorker = toAff <<< createWorker_

foreign import runWorkerImpl :: Fn1 Worker (Promise Unit)

runWorker_ :: Worker -> Promise Unit
runWorker_ = runFn1 runWorkerImpl

runWorker :: Worker -> Aff Unit
runWorker = toAff <<< runWorker_

foreign import shutdownWorkerImpl :: EffectFn1 Worker Unit

shutdownWorker :: Worker -> Effect Unit
shutdownWorker = runEffectFn1 shutdownWorkerImpl

foreign import bundleWorkflowCodeImpl :: Fn1 BundleOptions (Promise WorkflowBundle)

bundleWorkflowCode_ :: BundleOptions -> Promise WorkflowBundle
bundleWorkflowCode_ = runFn1 bundleWorkflowCodeImpl

bundleWorkflowCode :: BundleOptions -> Aff WorkflowBundle
bundleWorkflowCode = toAff <<< bundleWorkflowCode_
