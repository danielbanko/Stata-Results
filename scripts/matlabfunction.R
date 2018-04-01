derivative <- function(x,y){
  .5(y-1)^2
}

euler <- function(h, start, finish, yinit){
  
  n <- (finish-start)/h
  table <- matrix(rep(0,(n+1)*4), nrow = n+1)
  colnames(table) <- c("Step", "Xn", "Yn", "f(xn, yn)")
  
  y <- yinit
  x <- start
  
  for (step in 0:n+1){
    
    table[step,] <- c(step - 1, x, y, derivative(x,y))
    y <- y+derivative(x,y)*h
    x <- x+h
    
  }
  
  return(table)
}