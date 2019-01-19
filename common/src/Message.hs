{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TemplateHaskell #-}
module Message
  where

import Protolude
import Data.Aeson (ToJSON, FromJSON)
import Data.Default
import Data.Time.Calendar
import Data.List.NonEmpty (NonEmpty)
import Control.Lens
import Reflex.Dom.WebSocket.Message

import Common

-- Messages

type AppRequest
  =
    -- Kanji/Vocab Browser
    KanjiFilter
  :<|> LoadMoreKanjiResults

  :<|> GetKanjiDetails
  :<|> LoadMoreKanjiVocab

  :<|> VocabSearch
  :<|> LoadMoreVocabSearchResult

  :<|> QuickAddSrsItem
  :<|> QuickToggleWakaru

  :<|> GetSrsStats

  -- Doing Review
  :<|> SyncReviewItems
  :<|> CheckAnswer

  -- Browsing Srs Items
  :<|> BrowseSrsItems
  :<|> GetSrsItem
  :<|> EditSrsItem
  :<|> BulkEditSrsItems

  :<|> AddOrEditDocument
  :<|> ListDocuments
  :<|> ListBooks
  :<|> ListArticles
  :<|> ViewDocument
  :<|> ViewRawDocument
  :<|> DeleteDocument

  :<|> QuickAnalyzeText

  :<|> GetReaderSettings
  :<|> SaveReaderSettings
  :<|> SaveReadingProgress

  :<|> GetVocabDetails
  :<|> GetVocabSentences
  :<|> GetRandomSentence
  :<|> LoadMoreSentences
  :<|> ToggleSentenceFav

  :<|> ImportSearchFields
  :<|> ImportData

------------------------------------------------------------
-- class CRUD t where
--   data KeyT t
--   data CreateT t
--   createT :: CreateT t -> t
--   readT :: KeyT t -> t
--   updateT :: KeyT t -> t -> ()
--   deleteT :: KeyT t -> ()
--   listT :: [t]

-- instance WebSocketMessage AppRequest (CreateT t) where
--   type ResponseT AppRequest (CreateT t) = (Maybe (KeyT t))

-- instance WebSocketMessage AppRequest (EditT t) where
--   type ResponseT AppRequest (CreateT t) = (Maybe (KeyT t))
----------------------------------------------------------------
data KanjiFilter = KanjiFilter
  { textContent :: Text
  , kanjiAdditionalFilter :: AdditionalFilter
  , selectedRadicals :: [RadicalId]
  }
  deriving (Generic, Show, ToJSON, FromJSON)

instance Default KanjiFilter where
  def = KanjiFilter "" def []

instance WebSocketMessage AppRequest KanjiFilter where
  type ResponseT AppRequest KanjiFilter = KanjiFilterResult

data KanjiFilterResult =
  KanjiFilterResult KanjiList --
                    [RadicalId] -- Valid Radicals
  deriving (Generic, Show, ToJSON, FromJSON)

type KanjiList =
   [(KanjiId, Kanji, Maybe Rank, [Meaning])]

----------------------------------------------------------------
data GetKanjiDetails =
  GetKanjiDetails KanjiId AdditionalFilter
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetKanjiDetails where
  type ResponseT AppRequest GetKanjiDetails = Maybe KanjiSelectionDetails

data VocabSrsState
  = NotInSrs
  | InSrs SrsEntryId
  | IsWakaru
  deriving (Eq, Ord, Generic, Show, ToJSON, FromJSON)

type VocabList = [(Entry, VocabSrsState)]

data KanjiSelectionDetails =
  KanjiSelectionDetails (KanjiDetails, VocabSrsState, [Text]) VocabList
  deriving (Generic, Show, ToJSON, FromJSON)

data LoadMoreKanjiVocab = LoadMoreKanjiVocab
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest LoadMoreKanjiVocab where
  type ResponseT AppRequest LoadMoreKanjiVocab = VocabList

----------------------------------------------------------------
data LoadMoreKanjiResults = LoadMoreKanjiResults
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest LoadMoreKanjiResults where
  type ResponseT AppRequest LoadMoreKanjiResults = KanjiList

----------------------------------------------------------------
data VocabSearch = VocabSearch Text (Maybe PartOfSpeech)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest VocabSearch where
  type ResponseT AppRequest VocabSearch = VocabList

data LoadMoreVocabSearchResult = LoadMoreVocabSearchResult
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest LoadMoreVocabSearchResult where
  type ResponseT AppRequest LoadMoreVocabSearchResult = VocabList

----------------------------------------------------------------
data QuickAddSrsItem = QuickAddSrsItem (Either KanjiId VocabId)
  (Maybe Text)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest QuickAddSrsItem where
  type ResponseT AppRequest QuickAddSrsItem = VocabSrsState

----------------------------------------------------------------
data QuickToggleWakaru = QuickToggleWakaru (Either KanjiId VocabId)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest QuickToggleWakaru where
  type ResponseT AppRequest QuickToggleWakaru = VocabSrsState

----------------------------------------------------------------

data GetSrsStats = GetSrsStats ()
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetSrsStats where
  type ResponseT AppRequest GetSrsStats =
    (SrsStats, SrsStats)

data SrsStats = SrsStats
  { reviewsToday :: Int
  , totalItems :: Int
  , totalReviews :: Int
  , averageSuccess :: Int
  }
  deriving (Generic, Show, ToJSON, FromJSON)

----------------------------------------------------------------
data BrowseSrsItems = BrowseSrsItems ReviewType BrowseSrsItemsFilter
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest BrowseSrsItems where
  type ResponseT AppRequest BrowseSrsItems = [SrsItem]

data BrowseSrsItemsFilter
  = BrowseDueItems SrsItemLevel
  | BrowseNewItems
  | BrowseSuspItems SrsItemLevel
  | BrowseOtherItems SrsItemLevel
  deriving (Generic, Show, ToJSON, FromJSON)

data SrsItemLevel = LearningLvl | IntermediateLvl | MatureLvl
  deriving (Eq, Ord, Generic, Show, ToJSON, FromJSON)

----------------------------------------------------------------
data ReviewItem = ReviewItem
  { _reviewItemId ::  SrsEntryId
  , _reviewItemField :: SrsEntryField
  , _reviewItemMeaning :: (NonEmpty Meaning, Maybe MeaningNotes)
  , _reviewItemReading :: (NonEmpty Reading, Maybe ReadingNotes)
  }
  deriving (Generic, Show, ToJSON, FromJSON)

getReviewItem
  :: (SrsEntryId, SrsEntry)
  -> ReviewItem
getReviewItem (i,s) =
  ReviewItem i (s ^. field) (m,mn) (r,rn)
  where
    m = (s ^. meaning)
    mn = (s ^. meaningNotes)
    r = (s ^. readings)
    rn = (s ^. readingNotes)

data SrsAction
  = DoSrsReview SrsEntryId Bool
  | SuspendItem SrsEntryId
  | BuryItem SrsEntryId
  deriving (Generic, Show, ToJSON, FromJSON)

data SyncReviewItems = SyncReviewItems ReviewType [SrsAction]
  (Maybe [SrsEntryId])
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest SyncReviewItems where
  type ResponseT AppRequest SyncReviewItems
    = Maybe ([ReviewItem], Int) -- Pending reviews

----------------------------------------------------------------
data CheckAnswer =
  CheckAnswer [Reading] [[(Double, Text)]]
  deriving (Generic, Show, ToJSON, FromJSON)

data CheckAnswerResult
  = AnswerCorrect
  | AnswerIncorrect Text
  deriving (Generic, Show, Eq, ToJSON, FromJSON)

instance WebSocketMessage AppRequest CheckAnswer where
  type ResponseT AppRequest CheckAnswer = CheckAnswerResult

----------------------------------------------------------------
data GetSrsItem = GetSrsItem SrsEntryId
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetSrsItem where
  type ResponseT AppRequest GetSrsItem
    = Maybe (SrsEntryId, SrsEntry)

----------------------------------------------------------------
data EditSrsItem = EditSrsItem SrsEntryId SrsEntry
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest EditSrsItem where
  type ResponseT AppRequest EditSrsItem = ()

----------------------------------------------------------------
data BulkEditSrsItems = BulkEditSrsItems ReviewType [SrsEntryId] BulkEditOperation
  deriving (Generic, Show, ToJSON, FromJSON)

data BulkEditOperation
  = SuspendSrsItems
  | MarkDueSrsItems
  | ChangeSrsReviewData Day
  | RemoveFromReviewType
  | AddBothReviewType
  | DeleteSrsItems
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest BulkEditSrsItems where
  type ResponseT AppRequest BulkEditSrsItems = Maybe ()

----------------------------------------------------------------
data AddOrEditDocument =
  AddOrEditDocument (Maybe ReaderDocumentId) Text Text
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest AddOrEditDocument where
  type ResponseT AppRequest AddOrEditDocument
    = (Maybe (ReaderDocumentData))

----------------------------------------------------------------
data ListDocuments = ListDocuments (Maybe Int)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ListDocuments where
  type ResponseT AppRequest ListDocuments
    = [(ReaderDocumentId, Text, Text)]

----------------------------------------------------------------
data ListBooks = ListBooks (Maybe Int)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ListBooks where
  type ResponseT AppRequest ListBooks
    = [(BookId, Text, Text)]

----------------------------------------------------------------
data ListArticles = ListArticles (Maybe Int)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ListArticles where
  type ResponseT AppRequest ListArticles
    = [(ArticleId, Text, Text)]

----------------------------------------------------------------
data ViewDocument
  = ViewDocument ReaderDocumentId (Maybe Int)
  | ViewBook BookId
  | ViewArticle ArticleId
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ViewDocument where
  type ResponseT AppRequest ViewDocument = (Maybe (ReaderDocumentData))

data ReaderDocumentData = ReaderDocumentData
  { _readerDocumentData_id             :: ReaderDocumentId
  , _readerDocumentData_title	       :: Text
  , _readerDocumentData_pg             :: (Int, Maybe Int)
  , _readerDocumentData_totalParaNum   :: Int
  , _readerDocumentData_slice          :: [(Int, AnnotatedPara)]
  } deriving (Generic, Show, ToJSON, FromJSON)

----------------------------------------------------------------
data ViewRawDocument = ViewRawDocument ReaderDocumentId
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ViewRawDocument where
  type ResponseT AppRequest ViewRawDocument = (Maybe (ReaderDocumentId, Text, Text))

----------------------------------------------------------------
data DeleteDocument = DeleteDocument ReaderDocumentId
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest DeleteDocument where
  type ResponseT AppRequest DeleteDocument
    = [(ReaderDocumentId, Text, Text)]

----------------------------------------------------------------
data QuickAnalyzeText = QuickAnalyzeText Text
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest QuickAnalyzeText where
  type ResponseT AppRequest QuickAnalyzeText
    = [(Int, AnnotatedPara)]

----------------------------------------------------------------
data GetReaderSettings = GetReaderSettings
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetReaderSettings where
  type ResponseT AppRequest GetReaderSettings = ReaderSettings CurrentDb

----------------------------------------------------------------
data SaveReaderSettings = SaveReaderSettings (ReaderSettings CurrentDb)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest SaveReaderSettings where
  type ResponseT AppRequest SaveReaderSettings = ()

----------------------------------------------------------------
data SaveReadingProgress = SaveReadingProgress ReaderDocumentId (Int, Maybe Int)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest SaveReadingProgress where
  type ResponseT AppRequest SaveReadingProgress = ()

----------------------------------------------------------------
data GetVocabDetails = GetVocabDetails [VocabId]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetVocabDetails where
  type ResponseT AppRequest GetVocabDetails =
    [(Entry, VocabSrsState)]

----------------------------------------------------------------
data GetVocabSentences = GetVocabSentences (Either VocabId SrsEntryId)
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetVocabSentences where
  type ResponseT AppRequest GetVocabSentences =
    ([VocabId], [((Bool, SentenceId), SentenceData)]) -- Bool -> not favourite

----------------------------------------------------------------
data GetRandomSentence
  = GetRandomSentence
  | GetRandomFavSentence
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest GetRandomSentence where
  type ResponseT AppRequest GetRandomSentence =
    (((Bool, SentenceId), SentenceData)) -- Bool -> not favourite

----------------------------------------------------------------
data LoadMoreSentences = LoadMoreSentences [VocabId] [SentenceId]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest LoadMoreSentences where
  type ResponseT AppRequest LoadMoreSentences =
    [((Bool, SentenceId), SentenceData)] -- Bool -> not favourite

----------------------------------------------------------------
data ToggleSentenceFav = ToggleSentenceFav SentenceId
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ToggleSentenceFav where
  type ResponseT AppRequest ToggleSentenceFav = ()

----------------------------------------------------------------
data ImportSearchFields = ImportSearchFields [(Int, NonEmpty Text)]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ImportSearchFields where
  type ResponseT AppRequest ImportSearchFields =
    ([(Text, Either () SrsEntryId)]
     , [(NonEmpty VocabId, Text)]
     , [NonEmpty Text])

data NewEntryUserData = NewEntryUserData
  { mainField :: NonEmpty Text
  , meaningField :: NonEmpty Text
  , readingField :: [Text]
  , readingNotesField :: [Text]
  , meaningNotesField :: [Text]
  }
  deriving (Eq, Generic, Show, ToJSON, FromJSON)

data NewEntryOp
  = AddVocabs (NonEmpty VocabId)
  | AddCustomEntry NewEntryUserData [VocabId]
  | MarkWakaru (NonEmpty VocabId)
  deriving (Eq, Generic, Show, ToJSON, FromJSON)

data ImportData = ImportData [NewEntryOp]
  deriving (Generic, Show, ToJSON, FromJSON)

instance WebSocketMessage AppRequest ImportData where
  type ResponseT AppRequest ImportData = ()

----------------------------------------------------------------
makeLenses ''ReaderDocumentData

-- makeLenses ''ReviewItem
reviewItemField :: Lens' ReviewItem SrsEntryField
reviewItemField
  f_a23S8
  (ReviewItem x1_a23S9 x2_a23Sa x3_a23Sb x4_a23Sc)
  = fmap
      (\ y1_a23Sd -> ReviewItem x1_a23S9 y1_a23Sd x3_a23Sb x4_a23Sc)
      (f_a23S8 x2_a23Sa)
{-# INLINE reviewItemField #-}
reviewItemId :: Lens' ReviewItem SrsEntryId
reviewItemId
  f_a23Se
  (ReviewItem x1_a23Sf x2_a23Sg x3_a23Sh x4_a23Si)
  = fmap
      (\ y1_a23Sj -> ReviewItem y1_a23Sj x2_a23Sg x3_a23Sh x4_a23Si)
      (f_a23Se x1_a23Sf)
{-# INLINE reviewItemId #-}
reviewItemMeaning ::
  Lens' ReviewItem (NonEmpty Meaning, Maybe MeaningNotes)
reviewItemMeaning
  f_a23Sk
  (ReviewItem x1_a23Sl x2_a23Sm x3_a23Sn x4_a23So)
  = fmap
      (\ y1_a23Sp -> ReviewItem x1_a23Sl x2_a23Sm y1_a23Sp x4_a23So)
      (f_a23Sk x3_a23Sn)
{-# INLINE reviewItemMeaning #-}
reviewItemReading ::
  Lens' ReviewItem (NonEmpty Reading, Maybe ReadingNotes)
reviewItemReading
  f_a23Sq
  (ReviewItem x1_a23Sr x2_a23Ss x3_a23St x4_a23Su)
  = fmap
      (\ y1_a23Sv -> ReviewItem x1_a23Sr x2_a23Ss x3_a23St y1_a23Sv)
      (f_a23Sq x4_a23Su)
{-# INLINE reviewItemReading #-}

