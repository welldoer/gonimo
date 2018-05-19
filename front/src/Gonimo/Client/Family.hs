{-|
Module      : Gonimo.Client.Family
Description : User facing Family API
Copyright   : (c) Robert Klotzner, 2018

Get online devices, get accounts belonging to a family. Invite new devices,
rename the family, rename devices in this family, ...
-}
module Gonimo.Client.Family where



import           Gonimo.Client.Prelude
import           Gonimo.Client.Reflex   (DynamicMap, MDynamic)
import qualified Gonimo.SocketAPI.Types as API



-- | Configuration for creating a `Family`.
--
data Config t
  = Config { -- | Claim an invitation by providing it's secret.
             --
             --   When the user clicks an invitation link it gets claimed,
             --   making the invitation unavailable for other parties.
             _onSetName          :: Event t Text

             -- | A new invitation will be created.
             --
             --   And will become the next `activeInvitation`.
           , _onCreateInvitation :: Event t ()

             -- | Create a short human readable code for the current `activeInvitation`.
             --
             --   Once created, `activeInvitationCode` will be set accordingly.
           , _onCreateCode       :: Event t ()

             -- | Change the name of a device in this family.
           , _onSetDeviceName    :: Event t (API.DeviceId, Text)
           } deriving (Generic)

-- | Family data.
--   All data belonging to the current active family should go here. Like
--   claimed invitations or user name, ...
data Family t
  = Family { -- | The `API.FamilyId` of this very family.
             _identifier            :: MDynamic t API.FamilyId
             -- | Invitations currently open for this family.
             --
             --   That is all invitations for this family that still exist: They
             --   were neither rejected nor accepted.
             --
             --   This value is `Nothing` until all invitations have been loaded from the server.
           , _openInvitations      :: MDynamic t (Invitations t)

             -- | The last invitation created by this device that was not yet accepted/rejected.
             --
             --   This value is `Nothing` if either there is no last invitation
             --   created by this device or if invitations have not yet been
             --   loaded - `openInvitations` is `Nothing` too.
           , _activeInvitation     :: MDynamic t API.InvitationId

             -- | A short (and short lived) code that can be typed in by the
             --   user in order to retrieve an invitation.
             --
             --   This code always belongs to `activeInvitation`. It is
             --   `Nothing` if none was created yet.
           , _activeInvitationCode :: MDynamic t API.InvitationCode
            }

-- | Map type for open invitations.
type Invitations t = DynamicMap t API.InvitationId API.Invitation


instance Reflex t => Default (Config t) where
  def = mempty

instance Reflex t => Semigroup (Config t) where
  a <> b = Config { _onSetName          = leftmost [_onSetName a, _onSetName b]
                  , _onCreateInvitation = leftmost [ _onCreateInvitation a
                                                   , _onCreateInvitation b
                                                   ]
                  , _onCreateCode       = leftmost [_onCreateCode a, _onCreateCode b]
                  , _onSetDeviceName    = leftmost [ _onSetDeviceName a
                                                   , _onSetDeviceName b
                                                   ]
                  }

instance Reflex t => Monoid (Config t) where
  mempty = Config never never never never
  mappend = (<>)

instance Flattenable Config where
  flattenWith doSwitch ev
    = Config
      <$> doSwitch never (_onSetName <$> ev)
      <*> doSwitch never (_onCreateInvitation <$> ev)
      <*> doSwitch never (_onCreateCode <$> ev)
      <*> doSwitch never (_onSetDeviceName <$> ev)

instance Flattenable Family where
  flattenWith doSwitch ev
    = Family
      <$> flattenDynamic doSwitch (_identifier <$> ev)
      <*> flattenDynamic doSwitch (_openInvitations <$> ev)
      <*> flattenDynamic doSwitch (_activeInvitation <$> ev)
      <*> flattenDynamic doSwitch (_activeInvitationCode <$> ev)

-- Auto generated lenses:


class HasConfig a where
  config :: Lens' (a t) (Config t)

  onSetName :: Lens' (a t) (Event t Text)
  onSetName = config . go
    where
      go :: Lens' (Config t) (Event t Text)
      go f config' = (\onSetName' -> config' { _onSetName = onSetName' }) <$> f (_onSetName config')


  onCreateInvitation :: Lens' (a t) (Event t ())
  onCreateInvitation = config . go
    where
      go :: Lens' (Config t) (Event t ())
      go f config' = (\onCreateInvitation' -> config' { _onCreateInvitation = onCreateInvitation' }) <$> f (_onCreateInvitation config')


  onCreateCode :: Lens' (a t) (Event t ())
  onCreateCode = config . go
    where
      go :: Lens' (Config t) (Event t ())
      go f config' = (\onCreateCode' -> config' { _onCreateCode = onCreateCode' }) <$> f (_onCreateCode config')


  onSetDeviceName :: Lens' (a t) (Event t (API.DeviceId, Text))
  onSetDeviceName = config . go
    where
      go :: Lens' (Config t) (Event t (API.DeviceId, Text))
      go f config' = (\onSetDeviceName' -> config' { _onSetDeviceName = onSetDeviceName' }) <$> f (_onSetDeviceName config')


instance HasConfig Config where
  config = id



class HasFamily a where
  family :: Lens' (a t) (Family t)

  identifier :: Lens' (a t) (MDynamic t API.FamilyId)
  identifier = family . go
    where
      go :: Lens' (Family t) (MDynamic t API.FamilyId)
      go f family' = (\identifier' -> family' { _identifier = identifier' }) <$> f (_identifier family')


  openInvitations :: Lens' (a t) (MDynamic t (Invitations t))
  openInvitations = family . go
    where
      go :: Lens' (Family t) (MDynamic t (Invitations t))
      go f family' = (\openInvitations' -> family' { _openInvitations = openInvitations' }) <$> f (_openInvitations family')


  activeInvitation :: Lens' (a t) (Dynamic t (Maybe API.InvitationId))
  activeInvitation = family . go
    where
      go :: Lens' (Family t) (Dynamic t (Maybe API.InvitationId))
      go f family' = (\activeInvitation' -> family' { _activeInvitation = activeInvitation' }) <$> f (_activeInvitation family')


  activeInvitationCode :: Lens' (a t) (Dynamic t (Maybe API.InvitationCode))
  activeInvitationCode = family . go
    where
      go :: Lens' (Family t) (Dynamic t (Maybe API.InvitationCode))
      go f family' = (\activeInvitationCode' -> family' { _activeInvitationCode = activeInvitationCode' }) <$> f (_activeInvitationCode family')


instance HasFamily Family where
  family = id

