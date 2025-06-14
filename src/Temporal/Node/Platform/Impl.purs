module Temporal.Node.Platform.Impl (lookupEnv, module F) where

import Prelude (($), (>>=), (<>))
import Effect (Effect)
import Effect.Exception (error)
import Control.Monad.Error.Class (liftMaybe)
import Node.Process (lookupEnv) as NP
import Fetch (fetch) as F

lookupEnv :: String -> Effect String
lookupEnv var = NP.lookupEnv var >>= \m -> liftMaybe (error $ var <> " not defined") m
