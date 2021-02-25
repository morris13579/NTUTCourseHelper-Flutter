import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter_app/src/R.dart';
import 'package:flutter_app/src/connector/CourseOadConnector.dart';
import 'package:flutter_app/ui/other/ErrorDialog.dart';
import 'package:get/get.dart';

import '../Task.dart';
import 'CourseOadSystemTask.dart';

class CourseOadAddCourseTask extends CourseOadSystemTask<String> {
  final id;

  CourseOadAddCourseTask(this.id) : super("CourseOadAddCourseTask");

  @override
  Future<TaskStatus> execute() async {
    TaskStatus status = await super.execute();
    if (status == TaskStatus.Success) {
      super.onStart(R.current.addCourse);
      QueryCourseResult queryResult = await CourseOadConnector.queryCourse(id);
      super.onEnd();
      print(
          "${queryResult.up} ${queryResult.down} ${queryResult.now} ${queryResult.sign}");
      if (!queryResult.success) {
        ErrorDialogParameter parameter = ErrorDialogParameter(
          title: R.current.error,
          desc: queryResult.msg,
          btnOkOnPress: () {
            Get.back();
          },
          btnOkText: R.current.sure,
          dialogType: DialogType.ERROR,
          offCancelBtn: true,
        );
        await super.onErrorParameter(parameter);
        return TaskStatus.GiveUp;
      } else if (queryResult.sign > 0) {
        queryResult.success = false;
        ErrorDialogParameter parameter = ErrorDialogParameter(
          title: R.current.warning,
          desc: "目前有${queryResult.sign}待簽核\n你確定要繼續加選嗎?",
          btnOkText: R.current.sure,
          dialogType: DialogType.WARNING,
        );
        if (await super.onErrorParameter(parameter) == TaskStatus.GiveUp) {
          return TaskStatus.GiveUp;
        }
      } else if (queryResult.now < queryResult.down) {
        queryResult.success = false;
        ErrorDialogParameter parameter = ErrorDialogParameter(
          title: R.current.warning,
          desc: "下限為${queryResult.down},目前人數為${queryResult.now}\n你確定要繼續加選嗎?",
          btnOkText: R.current.sure,
          dialogType: DialogType.WARNING,
        );
        if (await super.onErrorParameter(parameter) == TaskStatus.GiveUp) {
          return TaskStatus.GiveUp;
        }
      }
      super.onStart(R.current.addCourse);
      AddCourseResult addResult = await CourseOadConnector.addCourse(id);
      super.onEnd();
      if (addResult != null && addResult.success) {
        result = addResult.msg;
        ErrorDialogParameter parameter = ErrorDialogParameter(
          title: R.current.success,
          desc: result,
          btnCancelOnPress: null,
          btnOkText: R.current.sure,
          dialogType: DialogType.SUCCES,
          offCancelBtn: true,
        );
        await super.onErrorParameter(parameter);
        return (queryResult.success) ? TaskStatus.Success : TaskStatus.GiveUp;
      } else {
        String msg = (addResult == null || addResult.msg == null)
            ? R.current.error
            : addResult.msg;
        ErrorDialogParameter parameter = ErrorDialogParameter(
          desc: msg,
          btnOkText: R.current.sure,
          offCancelBtn: true,
        );
        await super.onErrorParameter(parameter);
        return TaskStatus.GiveUp;
      }
    }
    return status;
  }
}