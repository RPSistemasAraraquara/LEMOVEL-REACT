function ShowGrowl(TypeMessage, Title, Text, Icon, PositionX, PositionY, AnimationEnter, AnimationExit, Delay) {
    $.iGrowl({                
        type: TypeMessage,
        delay: Delay,
        title: Title,
        message: Text,
        icon: Icon,
        placement: {
            x: PositionX,
            y: PositionY
        },
        animShow: AnimationEnter,
        animHide: AnimationExit
    })    
};