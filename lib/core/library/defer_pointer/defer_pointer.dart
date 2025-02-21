import 'dart:collection';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
part 'deferred_pointer_handler_link.dart';
part 'deferred_pointer_handler.dart';

/// Create a StatelessWidget to wrap our RenderObjectWidget so we can bind to inherited widget.
class DeferPointer extends StatelessWidget {
  const DeferPointer({Key? key, required this.child, this.paintOnTop = false, this.link}) : super(key: key);
  final Widget child;

  /// child will be painted in the [DeferredPointerHandler] causing it to render on top of any siblings in the it's current context.
  final bool paintOnTop;

  /// an optional link that can be shared with a [DeferredPointerHandler],
  /// if not provided, `DeferredHitTestRegion.of()` will be called.
  final DeferredPointerHandlerLink? link;

  @override
  Widget build(BuildContext context) {
    final link = this.link ?? DeferredPointerHandler.of(context).link;
    return _DeferPointerRenderObjectWidget(link: link, child: child, deferPaint: paintOnTop);
  }
}

/// Single child render object returns a custom render object [_DeferPointerRenderObject]
class _DeferPointerRenderObjectWidget extends SingleChildRenderObjectWidget {
  const _DeferPointerRenderObjectWidget({required this.link, required Widget child, Key? key, required this.deferPaint})
      : super(child: child, key: key);

  final DeferredPointerHandlerLink link;

  final bool deferPaint;

  @override
  RenderObject createRenderObject(BuildContext context) => _DeferPointerRenderObject(link, deferPaint);

  @override
  void updateRenderObject(BuildContext context, _DeferPointerRenderObject renderObject) {
    renderObject.link = link;
    renderObject.deferPaint = deferPaint;
  }
}

class _DeferPointerRenderObject extends RenderProxyBox {
  _DeferPointerRenderObject(DeferredPointerHandlerLink link, this.deferPaint, {RenderBox? child}) : super(child) {
    this.link = link;
  }

  bool deferPaint;
  bool _linked = false;

  late DeferredPointerHandlerLink _link;
  DeferredPointerHandlerLink get link => _link;
  set link(DeferredPointerHandlerLink link) {
    _link = link;
    link.add(this);
    _linked = true;
  }

  @override
  set child(RenderBox? child) {
    if (_linked) {
      link.remove(this);
      _linked = false;
    }
    super.child = child;
    if (this.child != null) {
      link.add(this);
      _linked = true;
    }
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    link.add(this);
  }

  @override
  void detach() {
    link.remove(this);
    super.detach();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (deferPaint) return; // skip the draw if an ancestor is supposed to handle it
    context.paintChild(child!, offset);
  }

  @override
  void markNeedsPaint() {
    if (deferPaint) {
      _link.descendantNeedsPaint();
    } else {
      super.markNeedsPaint();
    }
  }
}
