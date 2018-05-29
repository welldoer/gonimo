{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards   #-}
{-# LANGUAGE RecursiveDo       #-}

{-|
Module      : Reflex.Dom.MDC.Dialog
Description : Material Design Dialog component.
Copyright   : (c) Robert Klotzner, 2018
-}

module Reflex.Dom.MDC.Dialog ( -- * Types and Classes
                               ConfigBase(..)
                             , HasConfigBase(..)
                             , Config
                             , Dialog(..)
                             , HasDialog(..)
                             , DialogHeaderBase(..)
                             , DialogHeader
                             -- * Creation
                             , make
                             -- * Utilities
                             , separator
                             ) where


import           Control.Lens

import           Data.Map                    (Map)
import           Data.Monoid                 ((<>))
import           Data.Text                   (Text)
import qualified Data.Text                   as T
import           Language.Javascript.JSaddle (liftJSM)
import           Data.List                   (delete)
import qualified Language.Javascript.JSaddle as JS
import           Reflex.Dom.Core
import           Control.Monad


import           Reflex.Dom.MDC.Internal


-- | Make text a type parameter for easy I18N. All text is wrapped in `Dynamic`, so the language can be changed at runtime.
data ConfigBase text t m a
  = ConfigBase { _onOpen    :: Event t ()
               , _onClose   :: Event t ()
               , _onDestroy :: Event t ()
               -- , _AriaLabel       :: Dynamic t text -- We will take care of aria stuff at some later point in time properly.
               -- , _AriaDescription :: Dynamic t text
               , _header    :: DialogHeaderBase text t m
               , _body      :: m a
               , _footer    :: m ()
               }


data DialogHeaderBase text t m = DialogHeaderHeading (Dynamic t text)
                               | DialogHeaderBare (m ())

type Config t m a = ConfigBase Text t m a

type DialogHeader t m = DialogHeaderBase Text t m

data Dialog t a
  = Dialog { _dialogOnAccepted :: Event t ()
           , _dialogOnCanceled :: Event t ()
           , _dialogResult     :: a
           }

make :: forall t m a. MDCConstraint t m => Config t m a -> m (Dialog t a)
make conf = mdo
    (onAddClass, triggerAddClass)       <- newTriggerEvent
    (onRemoveClass, triggerRemoveClass) <- newTriggerEvent

    (_dialogOnCanceled, triggerCancel) <- newTriggerEvent
    (_dialogOnAccepted, triggerAccept) <- newTriggerEvent

    (dialogTag, (surfaceTag, _dialogResult)) <- html conf dynAttrs

    -- make adapter with JS prototype.
    constr  <- liftJSM $ JS.eval ("window.reflexDomMDC.Dialog" :: Text)
    adapter <- liftJSM $ JS.new constr [ _element_raw dialogTag
                                       , _element_raw surfaceTag
                                       ]

    setHaskellCallback adapter "addClass"     (liftIOJSM . triggerAddClass)
    setHaskellCallback adapter "removeClass"  (liftIOJSM . triggerRemoveClass)
    setHaskellCallback adapter "notifyCancel" (liftIOJSM $ triggerCancel ())
    setHaskellCallback adapter "notifyAccept" (liftIOJSM $ triggerAccept ())

    let -- Foundation functions to call:
      jsOpen    = liftJSM . void $ adapter ^. JS.js0 ("open" :: Text)
      jsClose   = liftJSM . void $ adapter ^. JS.js0 ("close" ::Text)
      jsDestroy = liftJSM . void $ adapter ^. JS.js0 ("destroy" ::Text)

    performEvent_ $ jsOpen    <$ conf ^. onOpen
    performEvent_ $ jsClose   <$ conf ^. onClose
    performEvent_ $ jsDestroy <$ conf ^. onDestroy

    dynAttrs <- foldDyn id staticAttrs $ leftmost [ addClassAttr <$> onAddClass
                                                  , removeClassAttr <$> onRemoveClass
                                                  ]

    pure $ Dialog {..}

  where
    staticAttrs = "class" =: "mdc-dialog" <> "role" =: "alertdialog"


    addClassAttr :: Text -> Map Text Text -> Map Text Text
    addClassAttr className = at "class" . non T.empty %~ addClass className

    removeClassAttr :: Text -> Map Text Text -> Map Text Text
    removeClassAttr className = at "class" . non T.empty %~ removeClass className

    addClass :: Text -> Text -> Text
    addClass className classes = classes <> " " <> className

    removeClass :: Text -> Text -> Text
    removeClass className classes = T.unwords . delete className . T.words $ classes

-- data DialogHtmlConfig
--   = DialogHtmlConfig { dialogHtmlConfigAttrs :: Dynamic t (Map Text Text)
--                      , dialogHtmlConfigBodyClass :: Dynamic t Text
--                      }
type ElementTuple t m a = (Element EventResult (DomBuilderSpace m) t, a)

html :: forall t m a. (DomBuilder t m, PostBuild t m)
           => Config t m a -> Dynamic t (Map Text Text) -> m (ElementTuple t m (ElementTuple t m a))
html conf dynAttrs = do
    r <-
      elDynAttr' "aside" dynAttrs $ do
        elClass' "div" "mdc-dialog__surface" $ do
          elClass "header" "mdc-dialog__header" $
            renderHeader $ conf ^. header
          a <-
            elClass "section" "mdc-dialog__body" $ conf ^. body
          elClass "footer" "mdc-dialog__footer" $ conf ^. footer
          pure a
    elClass "div" "mdc-dialog__backdrop" blank
    pure r
  where
    renderHeader :: DialogHeader t m -> m ()
    renderHeader (DialogHeaderHeading dt) = elClass "h2" "mdc-dialog__header__title" $ dynText dt
    renderHeader (DialogHeaderBare m)     = m


testDialog :: forall t m. MonadWidget t m => m (Dialog t ())
testDialog = make $ ConfigBase { _onOpen = never
                               , _onClose = never
                               , _onDestroy = never
                               , _header = DialogHeaderHeading (pure "hhuhu")
                               , _body = separator
                               , _footer = separator
                               }
-- Auto generated lenses:
class HasConfigBase a42 where
  configBase :: Lens' (a42 text t m a) (ConfigBase text t m a)

  onOpen :: Lens' (a42 text t m a) (Event t ())
  onOpen = configBase . go
    where
      go :: Lens' (ConfigBase text t m a) (Event t ())
      go f configBase' = (\onOpen' -> configBase' { _onOpen = onOpen' }) <$> f (_onOpen configBase')


  onClose :: Lens' (a42 text t m a) (Event t ())
  onClose = configBase . go
    where
      go :: Lens' (ConfigBase text t m a) (Event t ())
      go f configBase' = (\onClose' -> configBase' { _onClose = onClose' }) <$> f (_onClose configBase')


  onDestroy :: Lens' (a42 text t m a) (Event t ())
  onDestroy = configBase . go
    where
      go :: Lens' (ConfigBase text t m a) (Event t ())
      go f configBase' = (\onDestroy' -> configBase' { _onDestroy = onDestroy' }) <$> f (_onDestroy configBase')


  header :: Lens' (a42 text t m a) (DialogHeaderBase text t m)
  header = configBase . go
    where
      go :: Lens' (ConfigBase text t m a) (DialogHeaderBase text t m)
      go f configBase' = (\header' -> configBase' { _header = header' }) <$> f (_header configBase')


  body :: Lens' (a42 text t m a) (m a)
  body = configBase . go
    where
      go :: Lens' (ConfigBase text t m a) (m a)
      go f configBase' = (\body' -> configBase' { _body = body' }) <$> f (_body configBase')


  footer :: Lens' (a42 text t m a) (m ())
  footer = configBase . go
    where
      go :: Lens' (ConfigBase text t m a) (m ())
      go f configBase' = (\footer' -> configBase' { _footer = footer' }) <$> f (_footer configBase')


instance HasConfigBase ConfigBase where
  configBase = id

class HasDialog a42 where
  dialog :: Lens' (a42 t a) (Dialog t a)

  dialogOnAccepted :: Lens' (a42 t a) (Event t ())
  dialogOnAccepted = dialog . go
    where
      go :: Lens' (Dialog t a) (Event t ())
      go f dialog' = (\dialogOnAccepted' -> dialog' { _dialogOnAccepted = dialogOnAccepted' }) <$> f (_dialogOnAccepted dialog')


  dialogOnCanceled :: Lens' (a42 t a) (Event t ())
  dialogOnCanceled = dialog . go
    where
      go :: Lens' (Dialog t a) (Event t ())
      go f dialog' = (\dialogOnCanceled' -> dialog' { _dialogOnCanceled = dialogOnCanceled' }) <$> f (_dialogOnCanceled dialog')


  dialogResult :: Lens' (a42 t a) a
  dialogResult = dialog . go
    where
      go :: Lens' (Dialog t a) a
      go f dialog' = (\dialogResult' -> dialog' { _dialogResult = dialogResult' }) <$> f (_dialogResult dialog')


instance HasDialog Dialog where
  dialog = id

-- Content:
            -- elClass "div" "code-txt" $ do
            --   elClass "h2" "code-field" $ text "randomCode"
            --   elAttr "div" ("role" =: "progressbar" <> "class" =: "mdc-linear-progress") $ do
            --     elClass "div" "mdc-linear-progress__bar mdc-linear-progress__primary-bar"  $ do
            --       elClass "span" "mdc-linear-progress__bar-inner" blank
            --   elAttr "p" ("class" =: "mdc-text-field-helper-text--persistent" <> "aria-hidden" =: "true") $ do
            --     elAttr "i" ("class" =: "material-icons" <> "aria-hidden" =: "true") $ text "schedule"
            --     elClass "span" "code-time" $ text "0:30"
            --   elClass "div" "mdc-menu-anchor" $ do
            --     elAttr "button" ("type" =: "button" <> "class" =: "mdc-button mdc-button--flat btn share-btn") $ do
            --       elAttr "i" ("class" =: "material-icons" <> "aria-hidden" =: "true") $ text "share"
            --       text "Teilen"
            --     elAttr "div" ("class" =: "mdc-simple-menu" <> "tabindex" =: "-1") $ do
            --       elAttr "ul" ("class" =: "mdc-simple-menu__items mdc-list" <> "role" =: "menu" <> "aria-hidden" =: "true") $ do
            --         elAttr "li" ("class" =: "mdc-list-item" <> "role" =: "menuitem" <> "tabindex" =: "0") $ do
            --           elClass "i" "material-icons" $ text "mail"
            --           text "Mail"
            --         elAttr "li" ("class" =: "mdc-list-item" <> "role" =: "menuitem" <> "tabindex" =: "0") $ do
            --           elClass "i" "material-icons" $ text "content_copy"
            --           text "Kopieren"
            -- el "br" blank
            -- separator
            -- el "br" blank

-- Footer:

            -- elAttr "button" ("type" =: "button" <> "class" =: "mdc-button mdc-dialog__footer__button mdc-dialog__footer__button--cancel") $ text "Abbrechen"
