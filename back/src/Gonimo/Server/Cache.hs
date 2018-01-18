{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE ExplicitForAll #-}
{-|
Module      : Gonimo.Server.Cache
Description : Database cache.
Copyright   : (c) Robert Klotzner, 2017

Database cache needed for consistency and performance. The database cannot be
kept in sync with the reflex network efficiently, so in order for the clients to
hava a consistent view on the data we need to cache the data, the clients hold in
memory.

This cache is based on models, it does not know nothing about views and what data
is actually needed by clients, external code should make use of 'onLoadData' for
ensuring needed data is cached.

TODO: Statement about consistency still correct? We order db access and delay
  Update messages to the client until they are written to the db. So we know
  exactly which updates happened after a read and which happened before. Therefore
  the cache is no longer needed for consistency. It is still useful for
  authentication and stuff, but this opens the possibility of just clearing the
  cache completely from time to time, which would not have been possible before.
-}
module Gonimo.Server.Cache ( -- * Types and classes
                             Config(..)
                           , HasConfig(..)
                           , Cache
                           , Model(..)
                           , HasModel(..)
                           , ModelDump(..)
                           , HasModelDump(..)
                             -- * Creation
                           , make
                            -- * Common tasks
                           , getFamilyDevices
                           ) where

import Reflex
import Control.Lens
import Reflex.Behavior
import Control.Monad.Fix

import Gonimo.Server.Cache.Internal
import Gonimo.Server.Db.Internal (ModelDump(..), HasModelDump(..))
import Gonimo.SocketAPI.Model
import qualified Data.Set as Set
import qualified Gonimo.Server.Cache.FamilyAccounts as FamilyAccounts
import qualified Gonimo.Server.Cache.Devices        as Devices


make :: (MonadFix m, MonadHold t m, Reflex t) => Config t -> m (Cache t)
make conf = do
  -- Order of events is important here! 'onLoadModel' erases all data so it has to be
  -- last in the chain, so it woll be executed first. Then we execute 'loadData'
  -- and finally we execute 'onUpdate' which then is guaranteed to operate on
  -- the most current data.
  foldp id emptyModel $ mergeWith (.) [ conf^.onUpdate
                                      , loadDump <$> conf^.onLoadData
                                      , const <$> conf^.onLoadModel
                                      ]


-- | Get all devices belonging to a single family.
--
--   TODO: Function really needed? For getting a receiver list you should check ClientStatuses!
getFamilyDevices :: FamilyId -> Model -> [DeviceId]
getFamilyDevices fid model' =
  let
    accounts' :: [AccountId]
    accounts' = FamilyAccounts.getAccounts fid  (model' ^. familyAccounts)

    byAccountId' = model' ^. devices . to Devices.byAccountId
  in
    concatMap (\aid -> byAccountId' ^. at aid . non Set.empty . to Set.toList) accounts'

-- | Get the Account id of a given device.
-- getDeviceAccountId :: HasModel a => DeviceId -> a -> Maybe AccountId
-- getDeviceAccountId devId m = m ^? devices . at devId . _Just . to deviceAccountId
