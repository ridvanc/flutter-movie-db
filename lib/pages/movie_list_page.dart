import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'package:flutter_ui_challenge/model/movie_list.dart';
import 'package:flutter_ui_challenge/repository/movie_repository.dart';
import 'package:flutter_ui_challenge/widgets/movie_item_horizontal.dart';
import 'package:flutter_ui_challenge/widgets/movie_item_vertical.dart';

class MoviesListPage extends StatefulWidget {
  final int id;
  final String title;
  final MovieCat type;
  final FirebaseUser user; 

  MoviesListPage({
    Key key,
    this.id,
    this.title,
    this.type, 
    this.user,
  }) : super(key: key);

  @override
  _MoviesListPageState createState() => _MoviesListPageState();
}

class _MoviesListPageState extends State<MoviesListPage> {
  bool isVertical = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: isVertical ? Icon(Icons.grid_on) : Icon(Icons.list),
            onPressed: () {
              setState(() {
                isVertical = !isVertical;
              });
            },
          )
        ],
        title: Text(widget.title,
            style: TextStyle(
                // color: Theme.of(context).accentColor,
                // fontSize: ,
                // fontWeight: FontWeight.bold
                )),
      ),
      body: FutureBuilder(
        future: new MovieRepository().getMovies(widget.type, widget.id, 1),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.data == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return MovieListLayout(
            type: widget.type,
            id: widget.id,
            user: widget.user,
            movieList: snapshot.data,
            isVertical: isVertical,
          );
        },
      ),
    );
  }
}

class MovieListLayout extends StatefulWidget {
  final MovieList movieList;
  final MovieCat type;
  final int id;
  final bool isVertical;
  final FirebaseUser user;

  MovieListLayout(
      {Key key,
      this.movieList,
      this.type,
      this.id,
      this.isVertical,
      this.user})
      : super(key: key);

  @override
  _MovieListLayoutState createState() => _MovieListLayoutState();
}

class _MovieListLayoutState extends State<MovieListLayout> {
  ScrollController scrollController = ScrollController();

  List<Results> movies;

  int currentPage = 1;
  int totalPage;
  bool isLoading = false;

  void loadMoreMovies() async {
    var mMovies = await new MovieRepository()
        .getMovies(widget.type, widget.id, currentPage + 1);
    if (mMovies != null) {
      currentPage = mMovies.page;
      // print('$currentPage/$totalPage');
      mMovies.results.add(null);
      if (mounted)
        setState(() {
          isLoading = false;
          movies.addAll(mMovies.results);
        });
    }
  }

  bool onNotificatin(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      if (scrollController.position.maxScrollExtent ==
          scrollController.position.pixels) {
        // print("Ended:");
        // _appBloc.add(ListScrollEvent(load: true));
        if (!isLoading) {
          if (currentPage < totalPage) loadMoreMovies();
          isLoading = true;
        }
      }
    }
    return true;
  }

  @override
  void initState() {
    movies = widget.movieList.results;
    totalPage = widget.movieList.totalPages;
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isVertical
        ? NotificationListener(
            onNotification: onNotificatin,
            child: ListView.builder(
              controller: scrollController,
              physics: BouncingScrollPhysics(),
              itemCount: movies.length,
              // shrinkWrap: true,
              itemBuilder: (BuildContext context, int index) {
                // print(movies[index].title);
                // Movie movie=movies[index];
                if (index == movies.length - 1) {
                  movies.removeLast();
                  return Center(
                      child: SpinKitThreeBounce(
                    color: Colors.greenAccent,
                  ));
                }
                // if(movies[index]==null)
                //  return SizedBox.shrink();
                if (movies[index] != null) {
                  print(movies[index].title);
                  return MovieItemVertical(movie: movies[index],isLoggedIn: widget.user!=null,);
                }
                return SizedBox.shrink();
              },
            ),
          )
        : NotificationListener(
            onNotification: onNotificatin,
            child: GridView.builder(
              controller: scrollController,
              itemCount: movies.length,
              physics: BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                if (index == movies.length - 1) {
                  movies.removeLast();
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return MovieItemHorizontal(
                  movie: movies[index],
                  user: widget.user,
                );
              },
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  childAspectRatio: 0.5, crossAxisCount: 3),
            ),
          );
  }
}
