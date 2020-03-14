import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/debug/log/Log.dart';
import 'package:flutter_app/src/connector/CourseConnector.dart';
import 'package:flutter_app/src/connector/NTUTAppConnector.dart';
import 'package:flutter_app/src/store/Model.dart';
import 'package:flutter_app/src/taskcontrol/TaskHandler.dart';
import 'package:flutter_app/src/taskcontrol/TaskModelFunction.dart';
import 'package:flutter_app/src/taskcontrol/task/CheckCookiesTask.dart';
import 'package:flutter_app/src/taskcontrol/task/TaskModel.dart';
import 'package:flutter_app/ui/other/MyProgressDialog.dart';

class GraduationPicker {
  GraduationPickerWidget _dialog;
  BuildContext _context;
  BuildContext _dismissingContext;
  bool _barrierDismissible = true;
  bool _isShowing = false;

  GraduationPicker(BuildContext context, {bool isDismissible}) {
    _context = context;
    _barrierDismissible = isDismissible ?? _barrierDismissible; //是否之支援返回關閉
  }

  bool isShowing() {
    return _isShowing;
  }

  void dismiss() {
    if (_isShowing) {
      try {
        _isShowing = false;
        if (Navigator.of(_dismissingContext).canPop()) {
          Navigator.of(_dismissingContext).pop();
        }
      } catch (_) {}
    }
  }

  Future<bool> hide() {
    if (_isShowing) {
      try {
        _isShowing = false;
        Navigator.of(_dismissingContext).pop(true);
        return Future.value(true);
      } catch (_) {
        return Future.value(false);
      }
    } else {
      return Future.value(false);
    }
  }

  Future<bool> show() async {
    if (!_isShowing) {
      try {
        _dialog = GraduationPickerWidget();
        showDialog<dynamic>(
          context: _context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            _dismissingContext = context;
            return WillPopScope(
              onWillPop: () async => _barrierDismissible,
              child: Dialog(
                  insetAnimationDuration: Duration(milliseconds: 100),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8))),
                  child: _dialog),
            );
          },
        );
        // Delaying the function for 200 milliseconds
        // [Default transitionDuration of DialogRoute]
        await Future.delayed(Duration(milliseconds: 200));
        _isShowing = true;
        return true;
      } catch (_) {
        return false;
      }
    } else {
      return false;
    }
  }
}

class GraduationPickerWidget extends StatefulWidget {
  @override
  _GraduationPickerWidget createState() => _GraduationPickerWidget();
}

class _GraduationPickerWidget extends State<GraduationPickerWidget> {
  List<String> yearList = List();
  List<Map> divisionList = List();
  List<Map> departmentList = List();
  double width;
  String _selectedYear;
  Map _selectedDivision;
  Map _selectedDepartment;
  Map<String, String> _presetDepartment;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero).then((_) {
      _addPresetTask();
    });
  }

  Future<void> _addPresetTask() async {
    TaskHandler.instance.addTask(TaskModelFunction(context,
        require: [], taskFunction: () async {
      MyProgressDialog.showProgressDialog(context, "查詢中...");
      await NTUTAppConnector.login(
          Model.instance.getAccount(), Model.instance.getPassword());
      _presetDepartment = await NTUTAppConnector.getDepartment();
      MyProgressDialog.hideProgressDialog();
      if (_presetDepartment == null)
        return false;
      else
        return true;
    }, errorFunction: () {
      TaskHandler.instance.giveUpTask();
    }, successFunction: () {}));
    await TaskHandler.instance.startTaskQueue(context);
    _addSelectTask();
  }

  Future<void> _addSelectTask() async {
    if (_presetDepartment == null) {
      _presetDepartment = Map();
    }
    await _getYearList();
    //利用學號預設學年度
    String year = Model.instance.getAccount().substring(0, 3);
    for (String v in yearList) {
      if (v.contains(year)) {
        _selectedYear = v;
        break;
      }
    }
    await _getDivisionList();
    //利用北科行動助理預設學制與系所
    String presetDivision = _presetDepartment["division"];
    presetDivision = presetDivision ?? "";
    for (Map v in divisionList) {
      if (v["name"].contains(presetDivision)) {
        _selectedDivision = v;
        break;
      }
    }
    await _getDepartmentList();
    String presetDepartment = _presetDepartment["department"];
    presetDepartment = presetDepartment ?? "";
    for (Map v in departmentList) {
      if (v["name"].contains(presetDepartment)) {
        _selectedDepartment = v;
        break;
      }
    }
    setState(() {});
  }

  _showSelectList(List<String> listItems) async {
    int select = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: listItems.length,
          itemBuilder: (BuildContext context, int index) {
            return InkWell(
              child: Container(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  children: <Widget>[Text(listItems[index])],
                ),
              ),
              onTap: () {},
            );
          },
        );
      },
    );
  }

  Widget buildText(String title) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        Expanded(
          child: Text(title, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  List<DropdownMenuItem> buildYearList() {
    return yearList
        .map(
          (val) => DropdownMenuItem(
            value: val,
            child: buildText(val),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem> buildDivisionList() {
    return divisionList
        .map(
          (val) => DropdownMenuItem(
            value: val,
            child: buildText(val["name"]),
          ),
        )
        .toList();
  }

  List<DropdownMenuItem> buildDepartmentList() {
    return departmentList
        .map(
          (val) => DropdownMenuItem(
            value: val,
            child: buildText(val["name"]),
          ),
        )
        .toList();
  }

  Future<void> _getYearList() async {
    MyProgressDialog.showProgressDialog(context, "查詢學期中...");
    yearList = await CourseConnector.getYearList();
    //Log.d(yearList.toString());
    _selectedYear = yearList.first;
    MyProgressDialog.hideProgressDialog();
    setState(() {});
  }

  Future<void> _getDivisionList() async {
    MyProgressDialog.showProgressDialog(context, "查詢學制中...");
    String year = _selectedYear.split(" ")[1];
    divisionList = await CourseConnector.getDivisionList(year);
    //Log.d(divisionList.toString());
    _selectedDivision = divisionList.first;
    MyProgressDialog.hideProgressDialog();
    setState(() {});
  }

  Future<void> _getDepartmentList() async {
    MyProgressDialog.showProgressDialog(context, "查詢系所中...");
    Map<String, String> code = _selectedDivision["code"];
    departmentList = await CourseConnector.getDepartmentList(code);
    //Log.d(departmentList.toString());
    _selectedDepartment = departmentList.first;
    MyProgressDialog.hideProgressDialog();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    width = MediaQuery.of(context).size.width;
    width = width * 0.8;
    return Container(
      width: width,
      color: Colors.white,
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                "畢業學分標準設定",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: DropdownButton(
                      isExpanded: true, //裡面元素是否要Expanded
                      value: _selectedYear,
                      items: buildYearList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedYear = value;
                          _getDivisionList();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: DropdownButton(
                      isExpanded: true,
                      value: _selectedDivision,
                      items: buildDivisionList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDivision = value;
                          _getDepartmentList();
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: DropdownButton(
                      isExpanded: true,
                      value: _selectedDepartment,
                      items: buildDepartmentList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDepartment = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  FlatButton(
                    child: Text("取消"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  FlatButton(
                    child: Text("儲存"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}