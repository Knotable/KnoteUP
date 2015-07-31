@Function::constants = (obj) -> #https://gist.github.com/eluck/74a5a8f8262d85497ab6
  for key, value of obj
    Object.defineProperty @prototype, key, value: value, writable: false, enumerable: true