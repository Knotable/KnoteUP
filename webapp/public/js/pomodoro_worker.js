var i = 0;

func = function () {
    i = i + 1;
    postMessage(i);
    setTimeout(func, 1000);
}

func();