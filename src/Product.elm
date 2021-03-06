module Product exposing (Product, productCollectionData, productDecoder, productPreview, productSingleData)

import DataSource exposing (DataSource)
import DataSource.File as File
import DataSource.Glob as Glob
import Html as H exposing (Html)
import Html.Attributes as A
import List.Extra exposing (unique)
import OptimizedDecoder as Decode exposing (Decoder)
import Page exposing (Page, PageWithState, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path exposing (..)
import Route
import Shared exposing (..)
import Time
import View exposing (View)



-- Products
-- contains all data definitions fot the Product type
-- TODO: convert body to Markdown


type alias Product =
    { body : Markdown
    , slug : String
    , title : String
    , publishDate : Time.Posix
    , productImages : List Shared.PageImage
    }


productCollectionData : DataSource (List Product)
productCollectionData =
    Glob.succeed
        (\filePath slug ->
            { filePath = filePath
            , slug = slug
            }
        )
        |> Glob.captureFilePath
        |> Glob.match (Glob.literal "site/products/")
        |> Glob.capture Glob.wildcard
        |> Glob.match (Glob.literal ".md")
        |> Glob.toDataSource
        |> DataSource.map
            (List.map
                (\product ->
                    File.bodyWithFrontmatter (productDecoder product.slug) product.filePath
                )
            )
        |> DataSource.resolve


productSingleData : String -> DataSource Product
productSingleData slug =
    File.bodyWithFrontmatter
        (productDecoder slug)
        ("site/products/" ++ slug ++ ".md")


productDecoder : String -> Shared.Markdown -> Decoder Product
productDecoder slug body =
    Decode.map4 (Product body)
        (Decode.succeed slug)
        (Decode.field "title" Decode.string)
        (Decode.field "publish_date" Decode.string |> Decode.andThen Shared.dateDecoder)
        (Decode.field "product_images" (Decode.list Shared.pageImageDecoder))


productPreview : Product -> Html msg
productPreview product =
    let
        featuredImage =
            product.productImages
                |> List.head
                |> Maybe.map (\image -> H.img [ A.src image.src, A.alt image.alt ] [])
                |> Maybe.withDefault (H.text "")
    in
    H.div []
        [ H.div []
            [ featuredImage ]
        , H.h2 [] [ H.text product.title ]
        ]
