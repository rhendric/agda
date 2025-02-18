-- | Lenses for 'CommandLineOptions' and 'PragmaOptions'.
--
--   Add as needed.
--
--   Nothing smart happening here.

module Agda.Interaction.Options.Lenses where

import Control.Monad.IO.Class   ( MonadIO(..) )

import Data.Set (Set)
import qualified Data.Set as Set

import System.FilePath ((</>))

import Agda.TypeChecking.Monad.Base
import Agda.TypeChecking.Monad.State
import Agda.Interaction.Library (getPrimitiveLibDir)
import Agda.Interaction.Options

import Agda.Utils.Lens
import Agda.Utils.FileName
import Agda.Utils.WithDefault (pattern Value)

---------------------------------------------------------------------------
-- * Pragma options
---------------------------------------------------------------------------

class LensPragmaOptions a where
  getPragmaOptions  :: a -> PragmaOptions
  setPragmaOptions  :: PragmaOptions -> a -> a
  mapPragmaOptions  :: (PragmaOptions -> PragmaOptions) -> a -> a
  lensPragmaOptions :: Lens' PragmaOptions a
  -- lensPragmaOptions :: forall f. Functor f => (PragmaOptions -> f PragmaOptions) -> a -> f a

  -- default implementations
  setPragmaOptions     = mapPragmaOptions . const
  mapPragmaOptions f a = setPragmaOptions (f $ getPragmaOptions a) a

instance LensPragmaOptions CommandLineOptions where
  getPragmaOptions = optPragmaOptions
  setPragmaOptions opts st = st { optPragmaOptions = opts }
  lensPragmaOptions f st = f (optPragmaOptions st) <&> \ opts -> st { optPragmaOptions = opts }

instance LensPragmaOptions TCState where
  getPragmaOptions = (^.stPragmaOptions)
  setPragmaOptions = set stPragmaOptions
  lensPragmaOptions = stPragmaOptions

modifyPragmaOptions :: MonadTCState m => (PragmaOptions -> PragmaOptions) -> m ()
modifyPragmaOptions = modifyTC . mapPragmaOptions

---------------------------------------------------------------------------
-- ** Verbosity in the local pragma options
---------------------------------------------------------------------------

class LensVerbosity a where
  getVerbosity :: a -> Verbosity
  setVerbosity :: Verbosity -> a -> a
  mapVerbosity :: (Verbosity -> Verbosity) -> a -> a

  -- default implementations
  setVerbosity     = mapVerbosity . const
  mapVerbosity f a = setVerbosity (f $ getVerbosity a) a

instance LensVerbosity PragmaOptions where
  getVerbosity = _optVerbose
  setVerbosity is opts = opts { _optVerbose = is }

instance LensVerbosity TCState where
  getVerbosity = getVerbosity . getPragmaOptions
  mapVerbosity = mapPragmaOptions . mapVerbosity

modifyVerbosity :: MonadTCState m => (Verbosity -> Verbosity) -> m ()
modifyVerbosity = modifyTC . mapVerbosity

putVerbosity :: MonadTCState m => Verbosity -> m ()
putVerbosity = modifyTC . setVerbosity

---------------------------------------------------------------------------
-- * Command line options
---------------------------------------------------------------------------

class LensCommandLineOptions a where
  getCommandLineOptions :: a -> CommandLineOptions
  setCommandLineOptions :: CommandLineOptions -> a -> a
  mapCommandLineOptions :: (CommandLineOptions -> CommandLineOptions) -> a -> a

  -- default implementations
  setCommandLineOptions     = mapCommandLineOptions . const
  mapCommandLineOptions f a = setCommandLineOptions (f $ getCommandLineOptions a) a

instance LensCommandLineOptions PersistentTCState where
  getCommandLineOptions = stPersistentOptions
  setCommandLineOptions opts st = st { stPersistentOptions = opts }

instance LensCommandLineOptions TCState where
  getCommandLineOptions = getCommandLineOptions . stPersistentState
  mapCommandLineOptions = updatePersistentState . mapCommandLineOptions

modifyCommandLineOptions :: MonadTCState m => (CommandLineOptions -> CommandLineOptions) -> m ()
modifyCommandLineOptions = modifyTC . mapCommandLineOptions

---------------------------------------------------------------------------
-- ** Safe mode
---------------------------------------------------------------------------

type SafeMode = Bool

class LensSafeMode a where
  getSafeMode :: a -> SafeMode
  setSafeMode :: SafeMode -> a -> a
  mapSafeMode :: (SafeMode -> SafeMode) -> a -> a

  -- default implementations
  setSafeMode     = mapSafeMode . const
  mapSafeMode f a = setSafeMode (f $ getSafeMode a) a

instance LensSafeMode PragmaOptions where
  getSafeMode = optSafe
  setSafeMode is opts = opts { _optSafe = Value is } -- setSafeOption

instance LensSafeMode CommandLineOptions where
  getSafeMode = getSafeMode . getPragmaOptions
  mapSafeMode = mapPragmaOptions . mapSafeMode

instance LensSafeMode PersistentTCState where
  getSafeMode = getSafeMode . getCommandLineOptions
  mapSafeMode = mapCommandLineOptions . mapSafeMode

instance LensSafeMode TCState where
  getSafeMode = getSafeMode . getCommandLineOptions
  mapSafeMode = mapCommandLineOptions . mapSafeMode

modifySafeMode :: MonadTCState m => (SafeMode -> SafeMode) -> m ()
modifySafeMode = modifyTC . mapSafeMode

putSafeMode :: MonadTCState m => SafeMode -> m ()
putSafeMode = modifyTC . setSafeMode

-- | These builtins may use postulates, and are still considered --safe

builtinModulesWithSafePostulates :: Set FilePath
builtinModulesWithSafePostulates =
  primitiveModules `Set.union` (Set.fromList
  [ "Agda" </> "Builtin" </> "Bool.agda"
  , "Agda" </> "Builtin" </> "Char.agda"
  , "Agda" </> "Builtin" </> "Char" </> "Properties.agda"
  , "Agda" </> "Builtin" </> "Coinduction.agda"
  , "Agda" </> "Builtin" </> "Cubical" </> "Equiv.agda"
  , "Agda" </> "Builtin" </> "Cubical" </> "Glue.agda"
  , "Agda" </> "Builtin" </> "Cubical" </> "HCompU.agda"
  , "Agda" </> "Builtin" </> "Cubical" </> "Id.agda"
  , "Agda" </> "Builtin" </> "Cubical" </> "Path.agda"
  , "Agda" </> "Builtin" </> "Cubical" </> "Sub.agda"
  , "Agda" </> "Builtin" </> "Equality" </> "Erase.agda"
  , "Agda" </> "Builtin" </> "Equality.agda"
  , "Agda" </> "Builtin" </> "Float.agda"
  , "Agda" </> "Builtin" </> "Float" </> "Properties.agda"
  , "Agda" </> "Builtin" </> "FromNat.agda"
  , "Agda" </> "Builtin" </> "FromNeg.agda"
  , "Agda" </> "Builtin" </> "FromString.agda"
  , "Agda" </> "Builtin" </> "Int.agda"
  , "Agda" </> "Builtin" </> "IO.agda"
  , "Agda" </> "Builtin" </> "List.agda"
  , "Agda" </> "Builtin" </> "Maybe.agda"
  , "Agda" </> "Builtin" </> "Nat.agda"
  , "Agda" </> "Builtin" </> "Reflection.agda"
  , "Agda" </> "Builtin" </> "Reflection" </> "Properties.agda"
  , "Agda" </> "Builtin" </> "Reflection" </> "External.agda"
  , "Agda" </> "Builtin" </> "Sigma.agda"
  , "Agda" </> "Builtin" </> "Size.agda"
  , "Agda" </> "Builtin" </> "Strict.agda"
  , "Agda" </> "Builtin" </> "String.agda"
  , "Agda" </> "Builtin" </> "String" </> "Properties.agda"
  , "Agda" </> "Builtin" </> "Unit.agda"
  , "Agda" </> "Builtin" </> "Word.agda"
  , "Agda" </> "Builtin" </> "Word" </> "Properties.agda"
  ])

-- | These builtins may not use postulates under --safe. They are not
--   automatically unsafe, but will be if they use an unsafe feature.

builtinModulesWithUnsafePostulates :: Set FilePath
builtinModulesWithUnsafePostulates = Set.fromList
  [ "Agda" </> "Builtin" </> "TrustMe.agda"
  , "Agda" </> "Builtin" </> "Equality" </> "Rewrite.agda"
  ]

primitiveModules :: Set FilePath
primitiveModules = Set.fromList
  [ "Agda" </> "Primitive.agda"
  , "Agda" </> "Primitive" </> "Cubical.agda"
  ]

builtinModules :: Set FilePath
builtinModules = builtinModulesWithSafePostulates `Set.union`
                 builtinModulesWithUnsafePostulates

isPrimitiveModule :: MonadIO m => FilePath -> m Bool
isPrimitiveModule file = do
  libdirPrim <- liftIO getPrimitiveLibDir
  return (file `Set.member` Set.map (libdirPrim </>) primitiveModules)

isBuiltinModule :: MonadIO m => FilePath -> m Bool
isBuiltinModule file = do
  libdirPrim <- liftIO getPrimitiveLibDir
  return (file `Set.member` Set.map (libdirPrim </>) builtinModules)

isBuiltinModuleWithSafePostulates :: MonadIO m => FilePath -> m Bool
isBuiltinModuleWithSafePostulates file = do
  libdirPrim <- liftIO getPrimitiveLibDir
  let safeBuiltins   = Set.map (libdirPrim </>) builtinModulesWithSafePostulates
  return (file `Set.member` safeBuiltins)

---------------------------------------------------------------------------
-- ** Include directories
---------------------------------------------------------------------------

class LensIncludePaths a where
  getIncludePaths :: a -> [FilePath]
  setIncludePaths :: [FilePath] -> a -> a
  mapIncludePaths :: ([FilePath] -> [FilePath]) -> a -> a

  getAbsoluteIncludePaths :: a -> [AbsolutePath]
  setAbsoluteIncludePaths :: [AbsolutePath] -> a -> a
  mapAbsoluteIncludePaths :: ([AbsolutePath] -> [AbsolutePath]) -> a -> a

  -- default implementations
  setIncludePaths     = mapIncludePaths . const
  mapIncludePaths f a = setIncludePaths (f $ getIncludePaths a) a
  setAbsoluteIncludePaths     = mapAbsoluteIncludePaths . const
  mapAbsoluteIncludePaths f a = setAbsoluteIncludePaths (f $ getAbsoluteIncludePaths a) a

instance LensIncludePaths CommandLineOptions where
  getIncludePaths = optIncludePaths
  setIncludePaths is opts = opts { optIncludePaths = is }
  getAbsoluteIncludePaths = optAbsoluteIncludePaths
  setAbsoluteIncludePaths is opts = opts { optAbsoluteIncludePaths = is }

instance LensIncludePaths PersistentTCState where
  getIncludePaths = getIncludePaths . getCommandLineOptions
  mapIncludePaths = mapCommandLineOptions . mapIncludePaths
  getAbsoluteIncludePaths = getAbsoluteIncludePaths . getCommandLineOptions
  mapAbsoluteIncludePaths = mapCommandLineOptions . mapAbsoluteIncludePaths

instance LensIncludePaths TCState where
  getIncludePaths = getIncludePaths . getCommandLineOptions
  mapIncludePaths = mapCommandLineOptions . mapIncludePaths
  getAbsoluteIncludePaths = getAbsoluteIncludePaths . getCommandLineOptions
  mapAbsoluteIncludePaths = mapCommandLineOptions . mapAbsoluteIncludePaths

modifyIncludePaths :: MonadTCState m => ([FilePath] -> [FilePath]) -> m ()
modifyIncludePaths = modifyTC . mapIncludePaths

putIncludePaths :: MonadTCState m => [FilePath] -> m ()
putIncludePaths = modifyTC . setIncludePaths

modifyAbsoluteIncludePaths :: MonadTCState m => ([AbsolutePath] -> [AbsolutePath]) -> m ()
modifyAbsoluteIncludePaths = modifyTC . mapAbsoluteIncludePaths

putAbsoluteIncludePaths :: MonadTCState m => [AbsolutePath] -> m ()
putAbsoluteIncludePaths = modifyTC . setAbsoluteIncludePaths

---------------------------------------------------------------------------
-- ** Include directories
---------------------------------------------------------------------------

type PersistentVerbosity = Verbosity
class LensPersistentVerbosity a where
  getPersistentVerbosity :: a -> PersistentVerbosity
  setPersistentVerbosity :: PersistentVerbosity -> a -> a
  mapPersistentVerbosity :: (PersistentVerbosity -> PersistentVerbosity) -> a -> a

  -- default implementations
  setPersistentVerbosity     = mapPersistentVerbosity . const
  mapPersistentVerbosity f a = setPersistentVerbosity (f $ getPersistentVerbosity a) a

instance LensPersistentVerbosity PragmaOptions where
  getPersistentVerbosity = getVerbosity
  setPersistentVerbosity = setVerbosity

instance LensPersistentVerbosity CommandLineOptions where
  getPersistentVerbosity = getPersistentVerbosity . getPragmaOptions
  mapPersistentVerbosity = mapPragmaOptions . mapPersistentVerbosity

instance LensPersistentVerbosity PersistentTCState where
  getPersistentVerbosity = getPersistentVerbosity . getCommandLineOptions
  mapPersistentVerbosity = mapCommandLineOptions . mapPersistentVerbosity

instance LensPersistentVerbosity TCState where
  getPersistentVerbosity = getPersistentVerbosity . getCommandLineOptions
  mapPersistentVerbosity = mapCommandLineOptions . mapPersistentVerbosity

modifyPersistentVerbosity :: MonadTCState m => (PersistentVerbosity -> PersistentVerbosity) -> m ()
modifyPersistentVerbosity = modifyTC . mapPersistentVerbosity

putPersistentVerbosity :: MonadTCState m => PersistentVerbosity -> m ()
putPersistentVerbosity = modifyTC . setPersistentVerbosity
