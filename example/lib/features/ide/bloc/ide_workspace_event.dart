import 'package:polycode/polycode.dart';

sealed class IdeEvent {
  const IdeEvent();
}

class CreateFileRequested extends IdeEvent {
  const CreateFileRequested(this.fileName, {this.content = ''});
  final String fileName;
  final String content;
}

class DeleteFileRequested extends IdeEvent {
  const DeleteFileRequested(this.fileName);
  final String fileName;
}

class SelectFileRequested extends IdeEvent {
  const SelectFileRequested(this.fileName);
  final String fileName;
}

class CloseTabRequested extends IdeEvent {
  const CloseTabRequested(this.fileName);
  final String fileName;
}

class ToggleSearchRequested extends IdeEvent {
  const ToggleSearchRequested();
}

class SearchQueryChanged extends IdeEvent {
  const SearchQueryChanged(this.query);
  final String query;
}

class UpdateFileContentRequested extends IdeEvent {
  const UpdateFileContentRequested(this.fileName, this.content);
  final String fileName;
  final String content;
}

class LoadDemoProjectRequested extends IdeEvent {
  const LoadDemoProjectRequested(this.language);
  final PolyLanguage language;
}
