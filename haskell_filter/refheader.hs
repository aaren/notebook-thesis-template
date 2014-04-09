import Text.Pandoc
import Text.Pandoc.JSON

testForHeader :: [Block] -> Bool
testForHeader [] = False
testForHeader ((Header _ _ _) : blks) = True
testForHeader blks = False

isRefDiv :: Block -> Bool
isRefDiv (Div (id, classes, kvs) blks)
  | "references" `elem` classes = True
  | otherwise = False
isRefDiv blk = False

insertHeader :: [Inline] -> Block -> Block
insertHeader hdrInlines blk@(Div (id, classes, kvs) blks)
  | (not . testForHeader) blks, isRefDiv blk =
    Div
    (id, classes, kvs)
    ((Header 1 ("bibliography", ["unnumbered"], []) hdrInlines) : blks)
  | otherwise = blk
insertHeader _ blk = blk

refTitle :: Meta -> [Inline]
refTitle meta =
  case lookupMeta "ref-section-title" meta of
    Just (MetaString s)           -> [Str s]
    Just (MetaInlines ils)        -> ils
    Just (MetaBlocks [Plain ils]) -> ils
    Just (MetaBlocks [Para ils])  -> ils
    _                             -> [Str "References"]

isRefRemove :: Meta -> Bool
isRefRemove meta =
  case lookupMeta "remove-refs" meta of
    Just (MetaBool True) -> True
    _                    -> False

mkRefSec :: Pandoc -> Pandoc
mkRefSec p@(Pandoc meta blks)
  | isRefRemove meta = Pandoc meta (filter (not . isRefDiv) blks)
  | otherwise = Pandoc meta (map (insertHeader title) blks)
  where title = refTitle meta

main = toJSONFilter mkRefSec