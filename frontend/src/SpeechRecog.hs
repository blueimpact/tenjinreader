{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecursiveDo #-}
module SpeechRecog
  (speechRecogSetup, Result)
  where

import Protolude hiding (on)
import Control.Lens
import FrontendCommon
import qualified Data.Text as T

import GHCJS.DOM.SpeechRecognition
import GHCJS.DOM.SpeechRecognitionEvent
import GHCJS.DOM.SpeechGrammar
import GHCJS.DOM.EventM
import Data.JSString.Text

-- speechRecogWidget readings = do
--   -- TODO Do check on recogEv before this
--   respEv <- getWebSocketResponse $ CheckAnswer readings <$> recogEv
--   widgetHold (text "Waiting for Resp") $
--     (\t -> text $ T.pack $ show t) <$> respEv
--   ansDyn <- holdDyn (AnswerIncorrect "3") respEv
--   sendEv <- button "Next"
--   return $ (== AnswerCorrect) <$>
--     tagPromptlyDyn ansDyn sendEv

type Result = [[(Double, T.Text)]]

speechRecogSetup :: MonadWidget t m
  => m (Event t () -> m (Event t Result))
speechRecogSetup = do
  (trigEv, trigAction) <- newTriggerEvent

  recog <- liftIO $ do
    recog <- newSpeechRecognition
    -- Grammar does not work on chrome atleast
    recogGrammar <- newSpeechGrammarList
    let grammar = "#JSGF V1.0; grammar phrases; public <phrase> = (けいい) ;" :: [Char]
    addFromString recogGrammar grammar (Just 1.0)
    setGrammars recog recogGrammar
    setLang recog ("ja" :: [Char])
    setMaxAlternatives recog 5

    GHCJS.DOM.EventM.on recog result (onResultEv trigAction)
    return recog

  return (\e -> do
    performEvent (startRecognition recog <$ e)
    return trigEv)

onResultEv :: (Result -> IO ())
  -> EventM SpeechRecognition SpeechRecognitionEvent ()
onResultEv trigAction = do
  ev <- ask

  resL <- getResultList ev
  len <- getResultListLength resL

  let forM = flip mapM
  result <- forM [0 .. (len - 1)] $ (\i -> do
    res <- getResult resL i
    altLen <- getResultLength res
    forM [0 .. (altLen - 1)] $ (\j -> do
      alt <- getAlternative res j
      t <- getTranscript alt
      c <- getConfidence alt
      return (c, textFromJSString t)))

  liftIO $ trigAction result
