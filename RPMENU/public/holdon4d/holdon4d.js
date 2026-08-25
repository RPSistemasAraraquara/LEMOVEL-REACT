function ShowHoldOn(Theme, Text, TextColor, BackgroundColor, Callback) {
    let options = {
        theme: Theme,
        message: Text,
        textColor: TextColor
    };

    if (BackgroundColor) {
        options.backgroundColor = BackgroundColor;
    }

    ajaxCall(Callback, '');
    HoldOn.open(options);
}

function CloseHoldOn() {
    HoldOn.close();
}