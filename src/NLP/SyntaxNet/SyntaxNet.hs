{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RecordWildCards     #-}

module NLP.SyntaxNet.SyntaxNet
    ( readCnll
    , readCnll'
    ) where

import           Control.Applicative
import           Control.Concurrent
import qualified Control.Exception as E
import           Control.Lens
import           Control.Monad
import           Control.Monad.IO.Class
import           Data.Aeson
import           Data.Char
import           Data.Tree
import           Data.Maybe
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as BSC
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy as BSL
import           Data.Functor ((<$>))
import           Data.Csv ( DefaultOrdered (headerOrder)
                          , FromField (parseField)
                          , FromNamedRecord (parseNamedRecord)
                          , Header
                          , HasHeader(..)
                          , ToField (toField)
                          , ToNamedRecord (toNamedRecord)
                          , (.:)
                          , (.=)
                          , DecodeOptions(..)
                          )
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TEL
import qualified Data.Csv as Csv
import qualified Data.Vector as V

import           NLP.SyntaxNet.Types.CoNLL
import           NLP.SyntaxNet.Types.ParseTree

--------------------------------------------------------------------------------

readCnll :: FilePath -> IO [Token]
readCnll fpath = do 
  csvData <- BSL.readFile fpath 
  case TEL.decodeUtf8' csvData of
    Left  err  -> do
      putStrLn $ "error decoding" ++ (show err)
      return []
    Right dat  -> do
      let decodingResult = (Csv.decodeWith cnllOptions NoHeader $ TEL.encodeUtf8 dat) :: Either String (V.Vector Token)
      case decodingResult of
        Left err  -> do
          putStrLn $ "error decoding" ++ (show err)
          return [] 
        Right vals ->   
          return $ V.toList vals

-- | Reader for Named files with header
-- 
readCnll' :: FilePath -> IO [Token]
readCnll' fpath = do
  csvData <- BSL.readFile fpath 
  case TEL.decodeUtf8' csvData of
    Left  err  -> do
      putStrLn $ "error decoding" ++ (show err)
      return []
    Right dat  -> do
      let dat' = dat
      case decodeEntries $ TEL.encodeUtf8 dat' of
        Left  err  -> do
          putStrLn $ "error decoding" ++ (show err)
          return []
        Right vals -> do
          -- TODO: do additional operations
          return $ V.toList vals

          
decodeEntries :: BL.ByteString -> Either String (V.Vector Token)
decodeEntries = fmap snd . Csv.decodeByName

decodeEntries' :: BL.ByteString -> Either String (V.Vector Token)
decodeEntries' = fmap snd . Csv.decodeByName

preprocess :: TL.Text -> TL.Text
preprocess txt = TL.cons '\"' $ TL.snoc escaped '\"'
  where escaped = TL.concatMap escaper txt

escaper :: Char -> TL.Text
escaper c
  | c == '\t' = "\"\t\""
  | c == '\n' = "\"\n\""
  | c == '\"' = "\"\""
  | otherwise = TL.singleton c

-- | Define custom options to read tab-delimeted files
cnllOptions =
  Csv.defaultDecodeOptions
    { decDelimiter = fromIntegral (ord '\t')
    }

--------------------------------------------------------------------------------
-- Dealing with trees

readParseTree :: FilePath -> IO (Maybe (Tree Token))
readParseTree fpath = do
  treeData <- BSC.readFile fpath
  let ls = BSC.lines treeData

  let lls  = map ( \x -> BSC.split ' ' x) ls 
      lln  = map parseNode lls

  let tree = fromList lln 
  
  return $ tree

-- | Same as readParseTree but for debugging
-- 
readParseTree' :: FilePath -> IO ()
readParseTree' fpath = do
  treeData <- BSC.readFile fpath
  let ls = BSC.lines treeData

  mapM_ (putStrLn . show ) ls

  let lls  = map ( \x -> BSC.split ' ' x) ls
      lln  = map parseNode lls

  tree <- fromList' lln 

  --mapM_ (putStrLn . show ) lln
  putStrLn "----\n"
  putStrLn $ drawTree' $ fromJust tree
  
  return $ ()
  
parseNode :: [BSC.ByteString] -> Token
parseNode llbs = do
  let llss  =  map BSC.unpack llbs
      lenLB = 3                             -- useful labels like TOKEN POS ER
      lenWP = length $ filter (=="  ") llss -- each identation takes 2 spaces

  let lls  = map T.pack llss
      lvl  = (length lls) - lenLB - lenWP   -- calculate actual level  
      lbls = drop ((length lls) - 3) lls    -- extract only lables      

  Token lvl                                 -- reuse id to indicate level, when working with trees          
        (lbls!!0)
        ""
        UnkCg
        (parsePosFg $ T.unpack $ lbls!!1)
        ""
        0
        (parseGER $ T.unpack $ lbls!!2)
        ""
        ""
