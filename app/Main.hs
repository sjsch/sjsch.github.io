{-# LANGUAGE BlockArguments #-}
{-# LANGUAGE OverloadedStrings #-}

module Main where

import Data.Functor.Identity (runIdentity)
import Data.Text (Text)
import qualified Data.Text as T
import Hakyll
import Hakyll.Web.Sass
import Text.Pandoc.Options
import qualified Text.Pandoc.Templates as PT

main :: IO ()
main = hakyll do
  match "templates/*" (compile templateBodyCompiler)

  match "pages/index.html" do
    route (constRoute "index.html")
    compile do
      posts <- loadAll "posts/*" >>= recentFirst
      let indexCtx =
            listField "posts" postCtx (return posts) `mappend`
            defaultContext

      getResourceBody
        >>= applyAsTemplate indexCtx
        >>= loadAndApplyTemplate "templates/default.html" indexCtx
        >>= relativizeUrls

  match "posts/*" do
    route (setExtension "html")
    compile do
      pandocCompilerWith defaultHakyllReaderOptions writerOpts
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

  match "styles/*.scss" do
    route (setExtension "css")
    compile (fmap compressCss <$> sassCompiler)

writerOpts :: WriterOptions
writerOpts =
  defaultHakyllWriterOptions
    { writerTableOfContents = True,
      writerTemplate = Just tocTemplate
    }

tocTemplate :: PT.Template Text
tocTemplate =
  either error id . runIdentity . PT.compileTemplate "" $
    "<nav class=\"toc\">$toc$</nav>\n<article>$body$</article>"

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext
