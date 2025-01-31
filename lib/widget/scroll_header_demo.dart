import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_app/page_index.dart';

class ScrollHeaderDemoPage extends StatefulWidget {
  @override
  createState() => _ScrollHeaderDemoPageState();
}

class _ScrollHeaderDemoPageState extends State<ScrollHeaderDemoPage>
    with SingleTickerProviderStateMixin {
  GlobalKey<CustomSliverState> globalKey = GlobalKey();

  final ScrollController controller =
      ScrollController(initialScrollOffset: -70);

  double initLayoutExtent = 70;
  double showPullDistance = 150;
  final double indicatorExtent = 200;
  final double triggerPullDistance = 300;
  bool pinned = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColorDark,
      body: NotificationListener(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification) {
            if (initLayoutExtent > 0) {
              if (notification.metrics.pixels < -showPullDistance) {
                globalKey.currentState.handleShow();
              } else if (notification.metrics.pixels > 5) {
                globalKey.currentState.handleHide();
              }
            }
          }
          return false;
        },
        child: CustomScrollView(
          controller: controller,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: <Widget>[
            CustomSliver(
              key: globalKey,
              initLayoutExtent: initLayoutExtent,
              containerExtent: indicatorExtent,
              triggerPullDistance: triggerPullDistance,
              pinned: pinned,
            ),

            /// 列表区域
            SliverPadding(
              padding: EdgeInsets.only(bottom: pinned ? initLayoutExtent : 0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 2,
                ),

                ///代理显示
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return Card(
                      child: Container(
                        height: 60,
                        alignment: Alignment.centerLeft,
                        child: Text("Item $index"),
                      ),
                    );
                  },
                  childCount: 40,
                ),
              ),
            ),
          ],
        ),
      ),
      persistentFooterButtons: <Widget>[
        ElevatedButton(
          onPressed: () async {
            setState(() {
              pinned = !pinned;
            });
          },
          child: Text(
            pinned ? "pinned" : "scroll",
            style: TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              if (initLayoutExtent == 0) {
                initLayoutExtent = 70;
              } else {
                initLayoutExtent = 0;
                globalKey.currentState.handleShow();
              }
            });
          },
          child: Text(
            initLayoutExtent != 0 ? "minHeight" : "non Height",
            style: TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            setState(() {
              if (showPullDistance > 150) {
                showPullDistance = 150;
              } else {
                showPullDistance = 1500;
              }
            });
          },
          child: Text(
            showPullDistance > 150 ? "autoBack" : "non autoBack",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _CustomSliver extends SingleChildRenderObjectWidget {
  const _CustomSliver({
    Key key,
    this.containerLayoutExtent = 0.0,
    this.initLayoutExtent = 0.0,
    this.hasLayoutExtent = false,
    this.pinned = false,
    Widget child,
  })  : assert(containerLayoutExtent != null),
        assert(containerLayoutExtent >= 0.0),
        assert(hasLayoutExtent != null),
        super(key: key, child: child);

  final double initLayoutExtent;
  final double containerLayoutExtent;
  final bool hasLayoutExtent;
  final bool pinned;

  @override
  _RenderCustomSliver createRenderObject(BuildContext context) {
    return _RenderCustomSliver(
      containerExtent: containerLayoutExtent,
      initLayoutExtent: initLayoutExtent,
      hasLayoutExtent: hasLayoutExtent,
      pinned: pinned,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderCustomSliver renderObject) {
    renderObject
      ..containerLayoutExtent = containerLayoutExtent
      ..initLayoutExtent = initLayoutExtent
      ..pinned = pinned
      ..hasLayoutExtent = hasLayoutExtent;
  }
}

class _RenderCustomSliver extends RenderSliver
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderCustomSliver({
    @required double containerExtent,
    @required double initLayoutExtent,
    @required bool hasLayoutExtent,
    @required bool pinned,
    RenderBox child,
  })  : assert(containerExtent != null),
        assert(containerExtent >= 0.0),
        assert(hasLayoutExtent != null),
        _containerExtent = containerExtent,
        _initLayoutExtent = initLayoutExtent,
        _pinned = pinned,
        _hasLayoutExtent = hasLayoutExtent {
    this.child = child;
  }

  double get containerLayoutExtent => _containerExtent;
  double _containerExtent;

  set containerLayoutExtent(double value) {
    assert(value != null);
    assert(value >= 0.0);
    if (value == _containerExtent) return;
    _containerExtent = value;
    markNeedsLayout();
  }

  bool _pinned;

  set pinned(bool value) {
    assert(value != null);
    if (value == _pinned) return;
    _pinned = value;
    markNeedsLayout();
  }

  double _initLayoutExtent;

  set initLayoutExtent(double value) {
    assert(value != null);
    assert(value >= 0.0);
    if (value == _initLayoutExtent) return;
    _initLayoutExtent = value;
    markNeedsLayout();
  }

  bool get hasLayoutExtent => _hasLayoutExtent;
  bool _hasLayoutExtent;

  set hasLayoutExtent(bool value) {
    assert(value != null);
    if (value == _hasLayoutExtent) return;
    _hasLayoutExtent = value;
    markNeedsLayout();
  }

  ///for not pin and hide first
  double layoutExtentOffsetCompensation = 0.0;

  @override
  void performLayout() {
    assert(constraints.axisDirection == AxisDirection.down);
    assert(constraints.growthDirection == GrowthDirection.forward);
    double layoutExtent = (_hasLayoutExtent ? 1.0 : 0.0) * _containerExtent;
    if (_hasLayoutExtent == false &&
        _initLayoutExtent != null &&
        _initLayoutExtent > 0) {
      layoutExtent += _initLayoutExtent;
    }

    ///布局发生变化，调整 geometry
    if (layoutExtent != layoutExtentOffsetCompensation) {
      geometry = SliverGeometry(
        scrollOffsetCorrection: layoutExtent - layoutExtentOffsetCompensation,
      );
      layoutExtentOffsetCompensation = layoutExtent;
      return;
    }

    ///布局没有发生变化，滚动

    final bool active = constraints.overlap < 0.0 || layoutExtent > 0.0;
    final double overscrolledExtent =
        constraints.overlap < 0.0 ? constraints.overlap.abs() : 0.0;

    child.layout(
      constraints.asBoxConstraints(
        maxExtent: layoutExtent + overscrolledExtent,
      ),
      parentUsesSize: true,
    );

    if (active) {
      if (_pinned) {
        geometry = SliverGeometry(
          ///可滚动区域为 containerLayoutExtent 而已
          scrollExtent: containerLayoutExtent,

          /// 从 overlap 开始绘制
          paintOrigin: constraints.overlap,

          /// 绘制大小为自身大小或者残留大小
          paintExtent: min(layoutExtent, constraints.remainingPaintExtent),

          /// 布局大小
          layoutExtent: layoutExtent,

          ///最大可绘制区域
          maxPaintExtent: containerLayoutExtent,
          maxScrollObstructionExtent: _initLayoutExtent,
          cacheExtent: layoutExtent > 0.0
              ? -constraints.cacheOrigin + layoutExtent
              : layoutExtent,
          hasVisualOverflow:
              true, // Conservatively say we do have overflow to avoid complexity.
        );
      } else {
        var le = max(layoutExtent - constraints.scrollOffset, 0.0);

        ///必须保证 paintExtent <= constraints.remainingPaintExtent
        if (le > constraints.remainingPaintExtent) {
          le = constraints.remainingPaintExtent;
        }
        var paintExtent = max(
          max(child.size.height, layoutExtent) - constraints.scrollOffset,
          0.0,
        );

        ///必须保证 layoutExtent = paintExtent;
        if (paintExtent != le) {
          paintExtent = le;
        }

        geometry = SliverGeometry(
          scrollExtent: layoutExtent,
          paintOrigin: -overscrolledExtent - constraints.scrollOffset,
          paintExtent: paintExtent,
          maxPaintExtent: max(
            max(child.size.height, layoutExtent) - constraints.scrollOffset,
            0.0,
          ),
          maxScrollObstructionExtent: _initLayoutExtent,
          layoutExtent: le,
          hasVisualOverflow:
              true, // Conservatively say we do have overflow to avoid complexity.
        );
      }
    } else {
      geometry = SliverGeometry.zero;
    }
  }

  @override
  void paint(PaintingContext paintContext, Offset offset) {
    if (constraints.overlap < 0.0 ||
        constraints.scrollOffset + child.size.height > 0) {
      paintContext.paintChild(child, offset);
    }
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {double mainAxisPosition, double crossAxisPosition}) {
    if (child != null) {
      return child.hitTest(BoxHitTestResult.wrap(result),
          position: Offset(crossAxisPosition, mainAxisPosition));
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {}
}

typedef ContainerBuilder = Widget Function(
  BuildContext context,
  double pulledExtent,
  double triggerPullDistance,
  double containerExtent,
);

class CustomSliver extends StatefulWidget {
  const CustomSliver({
    Key key,
    this.triggerPullDistance = _defaultTriggerPullDistance,
    this.containerExtent = _defaultContainerExtent,
    this.initLayoutExtent = 0,
    this.pinned = false,
    this.builder = buildSimpleContainer,
  })  : assert(triggerPullDistance != null),
        assert(triggerPullDistance > 0.0),
        assert(containerExtent != null),
        assert(containerExtent >= 0.0),
        assert(
            triggerPullDistance >= containerExtent,
            'The  container cannot take more space in its final state '
            'than the amount initially created by overscrolling.'),
        super(key: key);

  final double triggerPullDistance;

  final double initLayoutExtent;

  final double containerExtent;

  final bool pinned;

  final ContainerBuilder builder;

  static const double _defaultTriggerPullDistance = 100.0;
  static const double _defaultContainerExtent = 60.0;

  static Widget buildSimpleContainer(
    BuildContext context,
    double pulledExtent,
    double triggerPullDistance,
    double containerExtent,
  ) {
    const Curve opacityCurve = Interval(0.0, 1, curve: Curves.easeInOut);
    return Stack(
      children: <Widget>[
        Opacity(
          opacity: 1.0,
          child: Container(color: Colors.red),
        ),
        Opacity(
          opacity:
              opacityCurve.transform(min(pulledExtent / containerExtent, 1.0)),
          child: InkWell(
            onTap: () {
              print("FFFF");
            },
            child: Container(
              color: Colors.amber,
              child: ImageLoadView(
                backgroundImage,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  createState() => CustomSliverState();
}

class CustomSliverState extends State<CustomSliver> {
  double latestcontainerBoxExtent = 0.0;
  bool hasSliverLayoutExtent = false;
  bool need = false;
  bool draging = false;

  handleShow() {
    if (hasSliverLayoutExtent != true) {
      setState(() => hasSliverLayoutExtent = true);
    }
  }

  handleHide() {
    if (hasSliverLayoutExtent != false) {
      setState(() => hasSliverLayoutExtent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CustomSliver(
      containerLayoutExtent: widget.containerExtent,
      initLayoutExtent: widget.initLayoutExtent,
      hasLayoutExtent: hasSliverLayoutExtent,
      pinned: widget.pinned,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          latestcontainerBoxExtent = constraints.maxHeight;
          if (widget.builder != null && latestcontainerBoxExtent > 0) {
            return widget.builder(
              context,
              latestcontainerBoxExtent,
              widget.triggerPullDistance,
              widget.containerExtent,
            );
          }
          return Container();
        },
      ),
    );
  }
}
