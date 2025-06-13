module Node.EsModule
  ( ModulePath
  , resolve
  ) where

import Effect (Effect)
import Effect.Aff.Compat (EffectFn1, runEffectFn1)

type Specifier = String

type ModulePath = String

type ImportMeta =
  { resolve :: EffectFn1 Specifier ModulePath
  }

foreign import importMeta :: ImportMeta

resolve :: Specifier -> Effect ModulePath
resolve s = runEffectFn1 importMeta.resolve s
