module Temporal.Logger.Argonaut (decode, decode') where

import Prelude (($), (<<<), show, bind)
import Data.Argonaut (decodeJson, parseJson)
import Data.Bifunctor (lmap)
import Data.Newtype as DN
import Effect.Exception (error)
import Temporal.Logger as TL

wrap = DN.wrap <<< error <<< show

decode input = TL.liftEither $ lmap wrap (decodeJson input)

decode' input = do
  input' <- TL.liftEither $ lmap wrap (parseJson input)
  decode input'
