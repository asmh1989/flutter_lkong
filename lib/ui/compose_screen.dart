import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lkongapp/actions/actions.dart';
import 'package:lkongapp/middlewares/api.dart';
import 'package:lkongapp/models/lkong_jsons/lkong_json.dart';
import 'package:lkongapp/ui/emoji_picker.dart';
import 'package:lkongapp/ui/modeled_app.dart';
import 'package:lkongapp/ui/tools/choose_image.dart';
import 'package:lkongapp/ui/tools/icon_message.dart';
import 'package:lkongapp/ui/tools/radio_dialog.dart';
import 'package:lkongapp/utils/cache_manager.dart';
import 'package:lkongapp/utils/utils.dart';

class ComposeScreen extends StatefulWidget {
  final Comment comment;
  final StoryInfoResult story;
  final Forum forum;
  final String username;
  final int uid;
  final ReplyType replyType;

  const ComposeScreen(
      {Key key,
      this.comment,
      this.story,
      this.forum,
      this.replyType,
      @required this.username,
      @required this.uid})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ComposeState();
  }
}

class ComposeState extends State<ComposeScreen> with WidgetsBindingObserver {
  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static final GlobalKey<FormState> _linkFormKey = GlobalKey<FormState>();

  static final String signatureLink = "http://lkong.cn/thread/2214383";
  static final String signaturePattern =
      "<br>--<a target='_blank' href='.*?'.*?>.*?</a>";
  static final String editorPattern =
      r"<i class=.pstatus.>.*?</i><br\s*[/]?><br\s*[/]?>";
  static final String quotaPattern =
      "<blockquote class=.lkquote.>[^]*?</blockquote>(<br>)?";

  final subjectController = TextEditingController();
  final contentController = TextEditingController();

  String initialContent;
  String initialSubject;

  bool alwaysSaveDraft = false;

  @override
  void dispose() {
    // Clean up the controller when the Widget is removed from the Widget tree
    if (!alwaysSaveDraft) {
      deleteDraft();
    } else {
      saveDraft();
    }

    WidgetsBinding.instance.removeObserver(this);
    subjectController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    initContent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      saveDraft();
    }
  }

  bool sending = false;
  int selectionStart;
  int selectionEnd;

  bool hasSignature(String s) {
    RegExp pattern = RegExp(signaturePattern);
    return pattern.hasMatch(s);
  }

  String appendSignature(BuildContext context, String content) {
    if (!hasSignature(content)) {
      String signatureRaw = stateOf(context)
              .persistState
              .appConfig
              .accountSettings
              .currentSetting
              ?.signature ??
          "";
      RegExp dotPattern = RegExp(r"'(\.\*\?)\'(\.\*\?)>(\.\*\?)");
      final signature = signaturePattern.replaceAllMapped(
          dotPattern, (Match m) => "'$signatureLink'>$signatureRaw");

      content = "$content $signature";
    }

    return content;
  }

  String finalizeContent(BuildContext context, String content) {
    RegExp newlinePattern = RegExp('\n');
    content = content.replaceAllMapped(newlinePattern, (Match m) => "<br>");
    content = appendSignature(context, content);

    return content;
  }

  String stripSignature(String content) {
    content =
        content.replaceFirstMapped(RegExp(signaturePattern), (Match m) => "");
    content =
        content.replaceFirstMapped(RegExp(editorPattern), (Match m) => "");
    content = content.replaceFirstMapped(
        RegExp(quotaPattern, multiLine: true), (Match m) => "");
    content = content.replaceAllMapped(RegExp(r"<br>"), (Match m) => "\n");
    return content;
  }

  void initContent() async {
    Map draft = await loadDraft();

    if (draft != null) {
      initialContent = draft["content"];
      initialSubject = draft["subject"];
    } else if (widget.replyType == ReplyType.EditComment ||
        widget.replyType == ReplyType.EditStory) {
      initialContent = widget.comment?.message;
      initialSubject = widget.story?.subject;
    }
  }

  Future<Map> loadDraft() async {
    Map draft;
    final draftFile = await getDraftFile();

    if (await draftFile.exists()) {
      String payload = draftFile.readAsStringSync();
      draft = json.decode(payload);
    }
    return draft;
  }

  void deleteDraft() async {
    File file = await getDraftFile();
    if (await file.exists()) {
      file.delete();
    }
  }

  void saveDraft() async {
    File file = await getDraftFile();

    String subject;

    switch (widget.replyType) {
      case ReplyType.Forum:
        subject = subjectController.text;
        break;
      case ReplyType.EditStory:
        subject = subjectController.text;
        break;
      default:
        break;
    }
    String content = contentController.text;
    if ((subject != null && subject.length > 0) ||
        (content != null && content.length > 0)) {
      String payload = json.encode({"subject": subject, "content": content});
      file.writeAsString(payload, flush: true);
    }
  }

  String _draftFile;

  Future<File> getDraftFile() async {
    if (_draftFile == null) {
      final folder = await CacheObject.cachePath;
      _draftFile = "$folder/._draft.sav";
    }
    return File(_draftFile);
  }

  void sendMessage(BuildContext context) {
    String subject;

    switch (widget.replyType) {
      case ReplyType.Forum:
        subject = subjectController.text;
        break;
      case ReplyType.EditStory:
        subject = subjectController.text;
        break;
      default:
        break;
    }
    String content = finalizeContent(context, contentController.text);

    final Completer<String> completer = Completer<String>();
    completer.future.then((error) {
      if (error == null) {
        subjectController.clear();
        contentController.clear();
        deleteDraft();
        dispatchAction(context)(UINavigationPop(context));
      } else {
        showToast("发帖失败: $error");
      }
      setState(() {
        this.sending = false;
      });
    });

    final now = DateTime.now().toUtc().toIso8601String();

    dispatchAction(context)(ReplyRequest(
      completer,
      author: widget.username,
      authorId: widget.uid,
      dateline: now,
      subject: subject,
      content: content,
      replyType: widget.replyType,
      forum: widget.forum,
      story: widget.story,
      comment: widget.comment,
    ));

    setState(() {
      this.sending = true;
    });
  }

  Future<String> _uploadImageWithAPI(File image, int api) {
    // print("Upload Image $image with API ${UPLOAD_IMAGE_API_NAMES[api]}");

    final callbacks = <String Function(Map)>[
      (result) {
        final String link = result["image"];
        if (link != null) {
          return link;
        }
        final String error = result["error"];
        throw Exception(error);
      },
      (result) {
        final List files = result["files"];
        final success = result["success"];
        String link;
        if (success && files != null && files.length > 0) {
          link = files[0]["url"];
        }
        if (link != null) {
          return link;
        }
        throw Exception();
      },
      (result) {
        final success = result["code"];
        final error = result["msg"];

        if (success != "success") {
          throw Exception("$error");
        }

        final data = result["data"];
        String link;
        if (data != null) {
          link = data["url"];
        }
        if (link != null) {
          return link;
        }
      },
      (result) {
        final data = result['result'];
        String link;
        if (data != null && data.length > 0) {
          link = data[0];
        }
        if (link != null) {
          return "https://i.ooxx.ooo/$link";
        }
        throw Exception();
      }
    ];

    setState(() {
      this.sending = true;
    });

    return apiDispatch(UPLOAD_IMAGE_API_LIST[api], {"file": image.path})
        .then((result) {
      setState(() {
        this.sending = false;
      });
      try {
        return callbacks[api](result);
      } catch (e) {
        final errMsg = e.toString().replaceFirst("Exception", "传图失败");

        showToast(errMsg);
      }
      return null;
    });
  }

  Future<String> _uploadImage(BuildContext context, File image) async {
    // print("Image $image");

    if (image != null) {
      int uploadAPI =
          stateOf(context).persistState.appConfig.setting.uploadImageAPI;
      if (uploadAPI > 0) {
        return _uploadImageWithAPI(image, uploadAPI - 1);
      } else {
        final Completer<String> completer = Completer<String>();
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => RadioDialog(
                  title: '选择图床',
                  selections: UPLOAD_IMAGE_API_NAMES,
                  onSelected: (int selected) {
                    if (selected != null &&
                        selected >= 0 &&
                        selected < UPLOAD_IMAGE_API_COUNT) {
                      final url = _uploadImageWithAPI(image, selected);
                      completer.complete(url);
                    } else {
                      completer.complete(null);
                    }
                  },
                ));
        return completer.future;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final config = stateOf(context).persistState.appConfig;
    final theme = LKModeledApp.modelOf(context).theme;
    String title;

    alwaysSaveDraft = (config.setting.alwaysSaveDraft == true);

    switch (widget.replyType) {
      case ReplyType.Forum:
        final forum = widget.forum;
        title = "发帖：${forum.name}";
        break;
      case ReplyType.Story:
        final story = widget.story;
        title = "回复：${story.subject}";
        break;
      case ReplyType.Comment:
        final comment = widget.comment;
        title = "回复：${comment.author}";
        break;
      case ReplyType.EditStory:
        final story = widget.story;
        title = "编辑：${story.subject}";
        break;
      case ReplyType.EditComment:
        final comment = widget.comment;
        title = "编辑：${comment.lou}楼";
        break;
    }

    if (subjectController.text.length == 0 && initialSubject != null) {
      subjectController.text = initialSubject;
      initialSubject = null;
    }
    if (contentController.text.length == 0 && initialContent != null) {
      contentController.text = stripSignature(initialContent);
      initialContent = null;
    }

    final ValueKey _subjectKey = LKongAppKeys.composeSubjectKey;
    final ValueKey _contentKey = LKongAppKeys.comoposeContentKey;

    final email = (widget.replyType == ReplyType.Forum ||
            widget.replyType == ReplyType.EditStory)
        ? TextFormField(
            key: _subjectKey,
            controller: subjectController,
            autofocus: false,
            validator: (val) =>
                val.isEmpty || val.trim().length == 0 ? '请输入标题' : null,
            decoration: InputDecoration(
              hintText: '标题',
              contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
            ),
          )
        : Container();

    final password = TextFormField(
      controller: contentController,
      key: _contentKey,
      autocorrect: false,
      keyboardType: TextInputType.multiline,
      maxLines: 1000,
      autofocus: true,
      validator: (val) =>
          val.isEmpty || val.trim().length == 0 ? '请输入内容' : null,
      decoration: InputDecoration(
        hintText: '内容',
        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
      ),
    );

    final form = Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          email,
          SizedBox(height: 8.0),
          Expanded(
            child: password,
          ),
          SizedBox(height: 32.0),
        ],
      ),
    );

    Widget bottomBar = BottomAppBar(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          SizedBox(
            width: 12.0,
          ),
          IconButton(
            color: theme.barIconColor,
            icon: Icon(Icons.add_photo_alternate),
            onPressed: () {
              final cursor = contentController.selection;
              selectionStart = cursor.start;
              selectionEnd = cursor.end;
              chooseImage(
                context,
                _scaffoldKey,
                cropping: config.setting.noCropImage != true,
                onChosen: (file) {
                  _uploadImage(context, file).then((link) {
                    if (link != null) {
                      insertImage(link);
                    }
                  });
                },
              );
            },
          ),
          SizedBox(
            width: 12,
          ),
          IconButton(
            color: theme.barIconColor,
            icon: Icon(Icons.insert_emoticon),
            onPressed: () {
              final cursor = contentController.selection;
              selectionStart = cursor.start;
              selectionEnd = cursor.end;
              dispatchAction(context)(UINavigationPush(
                  context, LKongAppRoutes.emojiPicker, builder: (context) {
                return EmojiPicker(
                  onEmojiTapped: (context, emid) {
                    final link = "http://img.lkong.cn/bq/em$emid.gif";
                    insertImage(link);
                  },
                );
              }));
            },
          ),
          SizedBox(
            width: 12,
          ),
          IconButton(
            color: theme.barIconColor,
            icon: Icon(Icons.link),
            onPressed: () {
              final cursor = contentController.selection;
              selectionStart = cursor.start;
              selectionEnd = cursor.end;
              onAddLinkTap(context);
            },
          ),
          Expanded(
              child: Container(
            height: 0.0,
          )),
        ],
      ),
    );

    final screen = Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.send),
              onPressed: (sending
                  ? null
                  : () {
                      if (!_formKey.currentState.validate()) {
                        return;
                      }
                      sendMessage(context);
                    }),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: form,
            ),
            bottomBar,
          ],
        ));

    if (!sending) {
      return screen;
    } else {
      return Stack(
        children: <Widget>[
          screen,
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
  }

  void insertImage(String link) {
    // final image = "[img]$link[/img]";
    final image = '<img src="$link" />';
    insertText(image);
  }

  void insertLink(String title, String link) {
    if (title == null || title.trim().length == 0) {
      title = link;
    }
    final achor = '<a href="$link"> $title </a>';
    insertText(achor);
  }

  void insertText(String inserted) {
    String text = contentController.text;
    if (text == null || text.length == 0) {
      contentController.text = inserted;
      selectionStart = inserted.length;
      selectionEnd = selectionStart;
    } else {
      if (selectionStart == null || selectionEnd == null) {
        final cursor = contentController.selection;
        selectionStart = cursor.start;
        selectionEnd = cursor.end;
      }

      if (selectionStart >= 0 && selectionEnd >= 0) {
        contentController.text =
            text.replaceRange(selectionStart, selectionEnd, inserted);
        selectionStart += inserted.length;
        selectionEnd = selectionStart;
      } else {
        contentController.text += inserted;
        selectionStart = contentController.text.length;
        selectionEnd = selectionStart;
      }
    }
    contentController.selection =
        TextSelection.fromPosition(TextPosition(offset: selectionStart));
  }

  void onAddLinkTap(BuildContext context) {
    final titleController = TextEditingController();
    final linkController = TextEditingController();

    final ValueKey _titleKey = Key('__addurl__title__');
    final ValueKey _linkKey = Key('__addurl__link__');

    final titleFld = TextFormField(
      key: _titleKey,
      controller: titleController,
      autofocus: true,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: '链接标题',
        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
      ),
    );

    final linkFld = TextFormField(
      key: _linkKey,
      controller: linkController,
      autocorrect: false,
      keyboardType: TextInputType.url,
      autofocus: false,
      validator: (val) =>
          val.isEmpty || val.trim().length == 0 ? '请输入链接' : null,
      decoration: InputDecoration(
        hintText: '链接地址',
        contentPadding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4.0)),
      ),
    );

    final form = Form(
      key: _linkFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('标题'),
            SizedBox(height: 4.0),
            titleFld,
            SizedBox(height: 8.0),
            Text('链接'),
            SizedBox(height: 4.0),
            linkFld,
            SizedBox(height: 18.0),
          ],
        ),
      ),
    );

    showDialog<void>(
      context: _scaffoldKey.currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('添加链接'),
          content: form,
          actions: <Widget>[
            FlatButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('确定'),
              onPressed: () {
                if (!_linkFormKey.currentState.validate()) {
                  return;
                }
                final title = titleController.text;
                final link = linkController.text.trim();
                insertLink(title, link);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
