module Gonimo.Server.NameGenerator (
                                   -- * Types
                                     FamilyName
                                   , FamilyNames
                                   , Predicates
                                   -- * Functions
                                   , loadFamilies
                                   , loadPredicates
                                   , generateFamilyName
                                   , generateDeviceName
                                   , makeDeviceName
                                   , getRandomVectorElement
                                   ) where

import           Control.Monad.IO.Class (MonadIO, liftIO)
import           Data.Monoid
import           Data.Text              (Text)
import qualified Data.Text              as T
import qualified Data.Text.IO           as T
import           Data.Vector            (Vector, (!))
import qualified Data.Vector            as V
import           Gonimo.Types (FamilyName (..), parseFamilyName)
import           System.Random          (getStdRandom, randomR)

import           Paths_gonimo_back

type FamilyNames = Vector FamilyName

type Predicates  = Vector Text

loadFamilies :: IO FamilyNames
loadFamilies = do
  fileName <- getDataFileName "data/families.txt"
  let parse = map parseFamilyName . T.lines
  V.fromList . parse <$> T.readFile fileName


loadPredicates :: IO Predicates
loadPredicates = do
  fileName <- getDataFileName "data/predicates.txt"
  let parse = map T.strip . T.lines
  V.fromList . parse <$> T.readFile fileName

generateFamilyName :: MonadIO m => Predicates -> FamilyNames -> m FamilyName
generateFamilyName predicates familyNames = do
  predicate <- getRandomVectorElement predicates
  fName <- getRandomVectorElement familyNames
  pure $ fName { familyNameName = predicate <> " " <> familyNameName fName }

generateDeviceName :: MonadIO m => Predicates -> FamilyName -> m Text
generateDeviceName predicates f = do
  predicate <- getRandomVectorElement predicates
  pure $ makeDeviceName predicate f

makeDeviceName :: Text -> FamilyName -> Text
makeDeviceName predicate f = predicate <> " " <> familyMemberName f

-- Internal helper
getRandomVectorElement :: MonadIO m => Vector a -> m a
getRandomVectorElement pool = do
  let upperBound = V.length pool - 1
  (pool !) <$> liftIO (getStdRandom (randomR (0, upperBound)))
