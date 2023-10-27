module Icon exposing (..)

import Html exposing (Html)
import Svg
import Svg.Attributes as SvgAttr


play : Html msg
play =
    Svg.svg
        [ SvgAttr.height "36"
        , SvgAttr.viewBox "0 -960 960 960"
        , SvgAttr.width "36"
        , SvgAttr.fill "#fbf9f6"
        ]
        [ Svg.path
            [ SvgAttr.d "M320-200v-560l440 280-440 280Zm80-280Zm0 134 210-134-210-134v268Z"
            ]
            []
        ]


stop : Html msg
stop =
    Svg.svg
        [ SvgAttr.height "36"
        , SvgAttr.viewBox "0 -960 960 960"
        , SvgAttr.width "36"
        , SvgAttr.fill "#fbf9f6"
        ]
        [ Svg.path
            [ SvgAttr.d "M320-640v320-320Zm-80 400v-480h480v480H240Zm80-80h320v-320H320v320Z"
            ]
            []
        ]


arrow : Html msg
arrow =
    Svg.svg
        [ SvgAttr.width "25"
        , SvgAttr.height "24"
        , SvgAttr.viewBox "0 0 25 24"
        , SvgAttr.fill "#fbf9f6"
        ]
        [ Svg.path
            [ SvgAttr.d "M24.0607 13.0607C24.6464 12.4749 24.6464 11.5251 24.0607 10.9393L14.5147 1.3934C13.9289 0.807612 12.9792 0.807612 12.3934 1.3934C11.8076 1.97918 11.8076 2.92893 12.3934 3.51472L20.8787 12L12.3934 20.4853C11.8076 21.0711 11.8076 22.0208 12.3934 22.6066C12.9792 23.1924 13.9289 23.1924 14.5147 22.6066L24.0607 13.0607ZM0 13.5H23V10.5H0V13.5Z"
            , SvgAttr.fill "#FBF9F6"
            ]
            []
        ]


delete : Html msg
delete =
    Svg.svg
        [ SvgAttr.height "24"
        , SvgAttr.viewBox "0 -960 960 960"
        , SvgAttr.width "24"
        , SvgAttr.fill "#fbf9f6"
        ]
        [ Svg.path
            [ SvgAttr.d "M280-120q-33 0-56.5-23.5T200-200v-520h-40v-80h200v-40h240v40h200v80h-40v520q0 33-23.5 56.5T680-120H280Zm400-600H280v520h400v-520ZM360-280h80v-360h-80v360Zm160 0h80v-360h-80v360ZM280-720v520-520Z"
            ]
            []
        ]
