port module Main exposing (main)

import Browser
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Icon
import Json.Decode as D
import Json.Encode as E
import Task
import Time



-- Ports


port ticked : (Int -> msg) -> Sub msg


port setPageTitle : String -> Cmd msg


port save : E.Value -> Cmd msg


port load : String -> Cmd msg


port gotShifts : (E.Value -> msg) -> Sub msg



-- Model


type alias Minutes =
    Int


type alias Model =
    { shifts : Dict Int Shift
    , time : Time.Posix
    , zone : Time.Zone
    , date : String
    }


type alias Shift =
    { start : Minutes
    , end : Maybe Minutes
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { shifts = Dict.fromList []
      , time = Time.millisToPosix 0
      , zone = Time.utc
      , date = ""
      }
    , Time.now
        |> Task.andThen
            (\time ->
                Time.here
                    |> Task.map (\here -> ( time, here ))
            )
        |> Task.perform GotTimeData
    )



-- Msg


type Msg
    = GotTimeData ( Time.Posix, Time.Zone )
    | GotShifts E.Value
    | Tick Int
    | StartShift
    | StopShift
    | RemoveShift Int
    | ChangeStartTime Int String
    | ChangeEndTime Int String
    | ChangeDate String



-- Update


updateWithSave : Msg -> Model -> ( Model, Cmd Msg )
updateWithSave msg model =
    let
        ( newModel, cmd ) =
            update msg model

        saveCmd =
            if newModel.shifts /= model.shifts then
                save <| encodeTracking newModel.date newModel.shifts

            else
                Cmd.none
    in
    ( newModel
    , Cmd.batch
        [ saveCmd
        , cmd
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotTimeData ( time, zone ) ->
            ( { model | time = time, date = posixToISODate zone time, zone = zone }
            , load <| posixToISODate zone time
            )

        GotShifts value ->
            let
                newShifts =
                    case D.decodeValue decodeShifts value of
                        Ok shifts ->
                            shifts
                                |> List.indexedMap Tuple.pair
                                |> Dict.fromList

                        Err _ ->
                            Dict.empty
            in
            ( { model | shifts = newShifts }, Cmd.none )

        Tick millis ->
            let
                pageTitle =
                    totalTrackedTime model.time model.zone model.shifts
                        |> minutesToHourAndMinutes
            in
            ( { model | time = Time.millisToPosix millis }, setPageTitle <| pageTitle ++ " - Marcação de Ponto" )

        StartShift ->
            ( { model
                | shifts =
                    Dict.insert
                        (Dict.size model.shifts)
                        { start = timeToMinutes model.zone model.time
                        , end = Nothing
                        }
                        model.shifts
              }
            , Cmd.none
            )

        StopShift ->
            ( { model
                | shifts =
                    Dict.update
                        (Dict.size model.shifts - 1)
                        (Maybe.map
                            (\shift ->
                                { shift | end = Just <| timeToMinutes model.zone model.time }
                            )
                        )
                        model.shifts
              }
            , Cmd.none
            )

        RemoveShift index ->
            ( { model
                | shifts =
                    Dict.remove
                        index
                        model.shifts
              }
            , Cmd.none
            )

        ChangeStartTime index newTime ->
            ( { model
                | shifts =
                    Dict.update
                        index
                        (Maybe.map
                            (\shift ->
                                { shift | start = Maybe.withDefault shift.start <| hoursAndMinutesToMinutes newTime }
                            )
                        )
                        model.shifts
              }
            , Cmd.none
            )

        ChangeEndTime index newTime ->
            ( { model
                | shifts =
                    Dict.update
                        index
                        (Maybe.map
                            (\shift ->
                                { shift
                                    | end =
                                        case newTime of
                                            "" ->
                                                Nothing

                                            notEmptyTime ->
                                                case hoursAndMinutesToMinutes notEmptyTime of
                                                    Just minutes ->
                                                        Just minutes

                                                    Nothing ->
                                                        shift.end
                                }
                            )
                        )
                        model.shifts
              }
            , Cmd.none
            )

        ChangeDate date ->
            let
                ( newDate, cmd ) =
                    case date of
                        "" ->
                            ( model.date, Cmd.none )

                        _ ->
                            ( date, load date )
            in
            ( { model | date = newDate }, cmd )



-- View


view : Model -> Html Msg
view model =
    let
        ( trackAction, trackIcon, trackColor ) =
            if isTracking model.shifts then
                ( StopShift, Icon.stop, class "bg-dark-shade" )

            else
                ( StartShift, Icon.play, class "bg-dark-accent" )

        timeTracked =
            totalTrackedTime model.time model.zone model.shifts
                |> minutesToHourAndMinutes
    in
    main_ [ class "w-full h-screen bg-light-shade flex flex-col items-center" ]
        [ section [ class "pt-9" ]
            [ input
                [ type_ "date"
                , value model.date
                , onInput ChangeDate
                ]
                []
            ]
        , span [ class "pt-16 text-5xl text-dark-shade" ]
            [ text timeTracked
            ]
        , section [ class "pt-8 flex flex-col gap-5 w-[408px]" ]
            [ button
                [ onClick trackAction
                , class "rounded-lg flex justify-center"
                , trackColor
                ]
                [ trackIcon ]
            , article [ class "bg-main h-[435px] rounded-lg" ]
                [ ul [ class "px-3 py-4 flex flex-col gap-2" ]
                    (viewShifts model.time model.zone model.shifts)
                ]
            ]
        ]


viewShifts : Time.Posix -> Time.Zone -> Dict Int Shift -> List (Html Msg)
viewShifts time zone shifts =
    shifts
        |> Dict.toList
        |> List.map (viewShift time zone)


viewShift : Time.Posix -> Time.Zone -> ( Int, Shift ) -> Html Msg
viewShift time zone ( index, shift ) =
    let
        ( endTime, totalTime ) =
            case shift.end of
                Just end ->
                    ( end, end - shift.start )

                Nothing ->
                    ( 0
                    , timeToMinutes zone time - shift.start
                    )
    in
    li [ class "grid grid-cols-10 gap-3 items-center" ]
        [ viewTimeInput
            { minutes = shift.start
            , onInput = ChangeStartTime index
            }
        , Icon.arrow
        , viewTimeInput
            { minutes = endTime
            , onInput = ChangeEndTime index
            }
        , span [ class "text-light-shade text-2xl col-span-2" ] [ text <| minutesToHourAndMinutes totalTime ]
        , button [ class "bg-danger w-9 h-9 rounded-lg flex justify-center items-center", onClick <| RemoveShift index ] [ Icon.delete ]
        ]


viewTimeInput : { minutes : Minutes, onInput : String -> Msg } -> Html Msg
viewTimeInput opts =
    input
        [ class "text-2xl col-span-3"
        , type_ "time"
        , value <| minutesToHourAndMinutes opts.minutes
        , onInput opts.onInput
        ]
        []



-- Helper


timeToMinutes : Time.Zone -> Time.Posix -> Minutes
timeToMinutes zone time =
    Time.toHour zone time * 60 + Time.toMinute zone time


minutesToHourAndMinutes : Minutes -> String
minutesToHourAndMinutes minutes =
    let
        toStrAppended =
            String.fromInt
                >> String.padLeft 2 '0'
    in
    toStrAppended (minutes // 60) ++ ":" ++ toStrAppended (modBy 60 minutes)


hoursAndMinutesToMinutes : String -> Maybe Minutes
hoursAndMinutesToMinutes time =
    let
        ( hours, minutes ) =
            case String.split ":" time of
                [ h, m ] ->
                    ( String.toInt h, String.toInt m )

                _ ->
                    ( Nothing, Nothing )
    in
    Maybe.map2
        (\h m -> h * 60 + m)
        hours
        minutes


isTracking : Dict Int Shift -> Bool
isTracking shifts =
    shifts
        |> Dict.toList
        |> List.any (\( _, shift ) -> shift.end == Nothing)


totalTrackedTime : Time.Posix -> Time.Zone -> Dict Int Shift -> Minutes
totalTrackedTime time zone shifts =
    shifts
        |> Dict.values
        |> List.map
            (\shift ->
                Maybe.withDefault (timeToMinutes zone time) shift.end
                    - shift.start
            )
        |> List.foldl (+) 0


posixToISODate : Time.Zone -> Time.Posix -> String
posixToISODate zone time =
    (String.fromInt <| Time.toYear zone time)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt <| monthToInt <| Time.toMonth zone time)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt <| Time.toDay zone time)



-- Decoder


decodeShifts : D.Decoder (List Shift)
decodeShifts =
    D.list decodeShift


decodeShift : D.Decoder Shift
decodeShift =
    D.map2 Shift
        (D.field "start" D.int)
        (D.field "end" D.int
            |> D.map
                (\end ->
                    if end == 0 then
                        Nothing

                    else
                        Just end
                )
        )



-- Encoder


encodeShifts : Dict Int Shift -> E.Value
encodeShifts shifts =
    shifts
        |> Dict.values
        |> E.list
            (\shift ->
                E.object
                    [ ( "start", E.int shift.start )
                    , ( "end", E.int <| Maybe.withDefault 0 shift.end )
                    ]
            )


encodeTracking : String -> Dict Int Shift -> E.Value
encodeTracking date shifts =
    E.object
        [ ( "date", E.string date )
        , ( "shifts", encodeShifts shifts )
        ]


monthToInt : Time.Month -> Int
monthToInt month =
    case month of
        Time.Jan ->
            1

        Time.Feb ->
            2

        Time.Mar ->
            3

        Time.Apr ->
            4

        Time.May ->
            5

        Time.Jun ->
            6

        Time.Jul ->
            7

        Time.Aug ->
            8

        Time.Sep ->
            9

        Time.Oct ->
            10

        Time.Nov ->
            11

        Time.Dec ->
            12



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ gotShifts GotShifts
        , ticked Tick
        ]



-- Main


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = updateWithSave
        , subscriptions = subscriptions
        }
