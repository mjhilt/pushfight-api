module Pushfight.Request exposing (Request(..), decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Request
    = NoRequest
    | TakebackRequested
    | DrawOffered


decodeRequestImpl : String -> Decoder Request
decodeRequestImpl request =
    case request of
        "no_request" ->
            Decode.succeed NoRequest

        "takeback_requested" ->
            Decode.succeed TakebackRequested

        "draw_offered" ->
            Decode.succeed DrawOffered

        other ->
            Decode.fail ("Unksnown request " ++ other)


decode : Decoder Request
decode =
    Decode.field "request" Decode.string
        |> Decode.andThen decodeRequestImpl


encode : Request -> Encode.Value
encode request =
    case request of
        NoRequest ->
            Encode.string "no_request"

        TakebackRequested ->
            Encode.string "takeback_requested"

        DrawOffered ->
            Encode.string "draw_offered"
