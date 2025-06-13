module Node.OpenAI.Activities (countWords) where

import Prelude (($), bind, discard)
import Data.Maybe (Maybe(Just))
import Data.Semigroup ((<>))
import Data.Show (show)
import Temporal.Exchange (ExchangeI, ExchangeO)
import Temporal.Node.Activity (useInput, output, liftOperation)
import Temporal.Node.Activity.Unsafe (unsafeRunActivity)
import Temporal.Node.Platform (liftLogger)
import Temporal.Logger (info)
import Promise (Promise)

countWords :: ExchangeI -> Promise ExchangeO
countWords i = unsafeRunActivity @String @(Maybe Int) do
  t <- useInput i
  liftOperation $ liftLogger $ info $ "Running CountWords for " <> t
  -- TODO implement countWords
  let out = 42
  liftOperation $ liftLogger $ info $ "Output: " <> show out
  output $ Just out
