module Pushfight.Request exposing (Request(..), decode, encode, toString)
import Pushfight.Color exposing (Color(..))
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Request
    = NoRequest
    | TakebackRequested (Color)
    | DrawOffered (Color)


decodeRequestImpl : String -> Decoder Request
decodeRequestImpl request =
    case request of
        "no_request" ->
            Decode.succeed NoRequest

        "takeback_requested_white" ->
            Decode.succeed (TakebackRequested White)

        "takeback_requested_black" ->
            Decode.succeed (TakebackRequested Black)

        "draw_offered_white" ->
            Decode.succeed (DrawOffered White)

        "draw_offered_black" ->
            Decode.succeed (DrawOffered Black)

        other ->
            Decode.fail ("Unksnown request " ++ other)


decode : Decoder Request
decode =
    Decode.field "request" Decode.string
        |> Decode.andThen decodeRequestImpl

toString : Request -> String
toString request =
    case request of
        NoRequest ->
            "no_request"

        TakebackRequested c ->
            case c of
                White ->
                    "takeback_requested_white"
                Black ->
                    "takeback_requested_black"


        DrawOffered c ->
            case c of
                White ->
                    "draw_offered_white"
                Black ->
                    "draw_offered_black"

encode : Request -> Encode.Value
encode request =
    toString request
    |> Encode.string

