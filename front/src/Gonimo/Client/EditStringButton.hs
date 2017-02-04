{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE GADTs #-}
module Gonimo.Client.EditStringButton (editStringButton) where

import Reflex.Dom
import Control.Lens
import Data.Map (Map)
import Data.Text (Text)
import Control.Monad.Fix (MonadFix)
import Gonimo.Client.Reflex.Dom
import Data.Monoid

type EditStringConstraint t m= (PostBuild t m, DomBuilder t m, MonadFix m, MonadHold t m, DomBuilderSpace m ~ GhcjsDomSpace)

editStringButton :: forall t m. EditStringConstraint t m
                      => Map Text Text -> m () -> m () -> Dynamic t Text -> m (Event t Text)
editStringButton attrs inner editStringText val = mdo
  (e, _ ) <- elAttr' "button" attrs $ inner
  let clicked = domEvent Click e
  editStringDialog <- holdDyn (pure never) $ leftmost [ const (editStringBox editStringText val) <$> clicked
                                                        , const (pure never) <$> gotAnswer
                                                        ]
  gotAnswer <- switchPromptly never =<< dyn editStringDialog
  pure $ push (pure . id) gotAnswer


editStringBox :: forall t m. EditStringConstraint t m => m () -> Dynamic t Text -> m (Event t (Maybe Text))
editStringBox editStringText val = do
  elClass "div" "hCenteredOverlay" $ do
    elClass "div" "vCenteredBox" $ do
      elClass "div" "panel panel-default" $ do
        elClass "div" "panel-heading" $ elClass "h3" "panel-title" $ editStringText
        elClass "div" "panel-body" $ do
          valEdit <- el "div" $ do
            val' <- sample $ current val
            textInput $ def & textInputConfig_initialValue .~ val'
                                       & textInputConfig_attributes .~ pure ("class" =: "form-control")
          el "div" $ do
            okClicked <- buttonAttr ("class" =: "btn btn-success" <> "role" =: "button" <> "type" =: "button") $ text "Ok"
            cancelClicked <- buttonAttr ("class" =: "btn btn-danger" <> "role" =: "button" <> "type" =: "button") $ text "Cancel"
            let editValue = current $ valEdit^.textInput_value
            pure $ leftmost [ const Nothing <$> cancelClicked, Just <$> tag editValue okClicked ]
