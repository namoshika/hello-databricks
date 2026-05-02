import src.code
import src.common.utils

def test_method1():
    assert src.common.utils.get_hoge() == "called get_hoge"

def test_method2():
    assert src.code.hello_func1(True) == "called hello_func1a"
    assert src.code.hello_func1(False) == "called hello_func1b"

def test_method3():
    assert src.code.hello_func2() == "called hello_func2"
