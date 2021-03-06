module Shared exposing (Data, Markdown, Model, Msg(..), PageImage, PublishedStatus(..), SharedMsg(..), Title, data, dateDecoder, pageImageDecoder, pubStatusDecoder, template, titleDecoder, toHumanDate)

import Browser.Navigation
import DataSource
import DataSource.File as File
import Html as H exposing (Html)
import Html.Attributes as A
import Iso8601
import OptimizedDecoder as Decode exposing (Decoder)
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import Time exposing (..)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Just OnPageChange
    }


type Msg
    = OnPageChange
        { path : Path
        , query : Maybe String
        , fragment : Maybe String
        }
    | SharedMsg SharedMsg


type alias Data =
    { navItems : List NavItem
    , siteName : String
    }


type SharedMsg
    = NoOp


type alias NavItem =
    { name : String
    , url : String
    }



-- Common types


type alias Markdown =
    String


type alias Title =
    { english : String
    , teReo : String
    }


type PublishedStatus
    = Draft
    | Published


type alias PageImage =
    { src : String
    , alt : String
    }


type alias Model =
    { showMobileMenu : Bool
    }


init :
    Maybe Browser.Navigation.Key
    -> Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : Path
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Cmd Msg )
init navigationKey flags maybePagePath =
    ( { showMobileMenu = False }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange _ ->
            ( { model | showMobileMenu = False }, Cmd.none )

        SharedMsg globalMsg ->
            ( model, Cmd.none )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : DataSource.DataSource Data
data =
    File.onlyFrontmatter siteMetaDecoder "site/global.md"



-- UTITLITY
-- Date formatting


toDay : Time.Weekday -> String
toDay weekday =
    case weekday of
        Mon ->
            "Monday"

        Tue ->
            "Tuesday"

        Wed ->
            "Wednesday"

        Thu ->
            "Thursday"

        Fri ->
            "Friday"

        Sat ->
            "Saturday"

        Sun ->
            "Sunday"


toMonth : Time.Month -> String
toMonth month =
    case month of
        Jan ->
            "January"

        Feb ->
            "Febrbuary"

        Mar ->
            "March"

        Apr ->
            "April"

        May ->
            "May"

        Jun ->
            "June"

        Jul ->
            "July"

        Aug ->
            "August"

        Sep ->
            "September"

        Oct ->
            "October"

        Nov ->
            "November"

        Dec ->
            "December"


toHumanDate : Time.Posix -> String
toHumanDate time =
    let
        day =
            toWeekday Time.utc time |> toDay

        date =
            String.fromInt <| Time.toDay Time.utc time

        month =
            Time.toMonth Time.utc time |> toMonth

        year =
            String.fromInt <| Time.toYear Time.utc time
    in
    String.concat [ day, ", ", date, " ", month, " ", year ]



-- DECODERS


siteMetaDecoder : Decoder Data
siteMetaDecoder =
    Decode.map2 Data
        (Decode.field "nav" (Decode.list navItemDecoder))
        (Decode.field "site-name" Decode.string)


navItemDecoder : Decoder NavItem
navItemDecoder =
    Decode.map2 NavItem
        (Decode.field "name" Decode.string)
        (Decode.field "url" Decode.string)


titleDecoder : Decoder Title
titleDecoder =
    Decode.map2 Title
        (Decode.field "english" Decode.string)
        (Decode.field "te_reo_maori" Decode.string)


pageImageDecoder : Decoder PageImage
pageImageDecoder =
    Decode.map2 PageImage
        (Decode.field "image" Decode.string)
        (Decode.field "alt" Decode.string)


pubStatusDecoder : Bool -> Decoder PublishedStatus
pubStatusDecoder status =
    if status == True then
        Decode.succeed Published

    else
        Decode.succeed Draft


dateDecoder : String -> Decoder Time.Posix
dateDecoder datestring =
    case Iso8601.toTime datestring of
        Err _ ->
            Decode.fail "Failure parsing date"

        Ok datetime ->
            Decode.succeed datetime


view :
    Data
    ->
        { path : Path
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : Html msg, title : String }
view sharedData page model toMsg pageView =
    { title = pageView.title
    , body =
        H.div [ A.class "avenir pa4" ]
            [ H.div []
                [ H.a [ A.href "/", A.title "Home" ] [ H.text "Pito Press" ]
                ]
            , H.nav []
                [ H.ul [ A.class "list dib pl0" ]
                    (List.map
                        (\a ->
                            H.li []
                                [ H.a [ A.href <| "/" ++ a.url ] [ H.text a.name ]
                                ]
                        )
                        sharedData.navItems
                    )
                ]
            , H.main_ [ A.class "mw8 center bg-white pa4" ] pageView.body
            ]
    }
