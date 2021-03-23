module Pushfight.Color exposing (Color(..), decode, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode


type Color
    = White
    | Black


decodeColorImpl : String -> Decoder Color
decodeColorImpl request =
    case request of
        "White" ->
            Decode.succeed White

        "Black" ->
            Decode.succeed Black

        other ->
            Decode.fail ("Unkown color " ++ other)


decode : Decoder Color
decode =
    Decode.field "color" Decode.string
        |> Decode.andThen decodeColorImpl


encode : Color -> Encode.Value
encode request =
    case request of
        White ->
            Encode.string "White"

        Black ->
            Encode.string "Black"
