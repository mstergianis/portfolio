---
date: 2025-03-20T15:14:40-04:00
description: "my first venture into custom binary encodings"
# image: ""
lastmod: 2025-03-20
showTableOfContents: true
tags: ["huffman","bits","encoding","compression"]
title: "Implementing Huffman Encoding From a Video"
type: "post"
params:
  github: "https://github.com/mstergianis/huffman/"
---

# Introduction

Back in 2017 I watched Tom Scott's video on Huffman encoding. And there it sat
in my brain until a week ago when I started watching [Tsoding's video on Byte
Pair Encoding](https://www.youtube.com/watch?v=6dCqR9p0yWY). Text compression
and encoding schemes have intrigued me for a while so now seemed like the right
time to take a crack at something like that.

{{< youtube JsTptu56GM8 >}}

I decided that with only the YouTube video as guidance I would implement Huffman
encoding.

To be fair, the video does an excellent job at describing the scheme.

# The Process

> Note: I won't be making attempts to ensure that my code snippets compile
> outright. But I will be copying and lightly modifying snippets from [the
> github repo](https://github.com/mstergianis/huffman/). So if you want to see
> how this all works you can check it out there.

Count the frequencies of all the characters
```go
freqTable := make(map[byte]int)
for _, b := range []byte(input) {
    if _, ok := freqTable[b]; !ok {
        freqTable[b] = 0
    }
    freqTable[b]++
}
```

Then take the frequencies and put them in a list sorted by their frequency.
```go
for char, freq := range freqTable {
    characters = append(characters, frequencyPair{char, freq})
}
sort.SliceStable(characters, func(i int, j int) bool {
    return characters[i].freq < characters[j].freq
})
```

Based on that sorted list you can start to create the tree. Which is done by
taking the least frequent elements (the first two elements in the list) and
joining them via a node, then putting that node back in the list. We do this
until we have only one element remaining.

```go
for len(nodes) > 1 {
    newNode := &Node{
        left: nodes[0],
        right: nodes[1],
    }
    nodes = append(nodes[2:], newNode)
    sort.SliceStable(nodes, func(i, j int) bool {
        return nodes[i].Freq() < nodes[j].Freq()
    })
}
head := nodes[0].(*Node)
return head
```

## The Need to Encode Sub-byte Elements

Now the fun part, and the part that the video glossed over the most! Writing the
encoded file to disk. You see your efforts to compress the text will be wasted
if you naively print out your encodings.


```go
for _, b := range []byte(input) {
    bytes, bitWidth := tree.Search(b)

    // no no... wait now
    f.Write(bytes)
}
```

This is because most of your encodings will be less than a full byte. In fact
that's why the `tree.Search` method returns the bitWidth.

So for this we have two structures in the codebase `BitStringWriter` for
encoding and `BitStringReader` for decoding.

We'll focus on `BitStringWriter` since this blog post will only cover encoding.
But feel free to poke around in the code if you want to understand how the
decoding process works at a fine level. At a high level it's basically just the
opposite of the encoding process.

The actual type definition of BitStringWriter 
```go
type BitStringWriter struct {
	buffer []byte
	offset int
}
```

is very similar to the go standard library's bytes.Buffer
```go
type Buffer struct {
	buf      []byte // contents are the bytes buf[off : len(buf)]
	off      int    // read at &buf[off], write at &buf[len(buf)]
	lastRead readOp // last read operation, so that Unread* can work correctly.
}
```

But here's where the differences start. Check out the type signatures for each
of the `Write` methods.

```go
func (bs *BitStringWriter) Write(b byte, w int)
func (b *bytes.Buffer) Write(p []byte) (n int, err error)
```

The return types aren't all that interesting. But what is interesting are the
arguments. Our method expects you to pass in a single `byte` and an `int`? It
doesn't conform to the [`io.Writer`](https://pkg.go.dev/io#Writer) interface...
So what good is it?

Well it allows you to write less than a byte. Let's say for example that we're
encoding the text "hello world". And the tree we've derived is as follows.

{{< media/svg src="/static/svgs/hello-world-graph.svg" >}}

When it comes time to write the first `h` we traverse the graph left, right,
then left. Leading to the encoding 010 with a bit width of 3.

So if we naively wrote this with a classical writer
```go
buf.Write([]byte{
    0b0000_0010, // writes h
    0b0000_1110, // writes e
    0b0000_0010, // writes l
})
```

We would be writing 3 bytes where we could actual write 9 bits.

This is where the `BitStringWriter` shines. When we write
```go
bs.Write(0b010, 3)
// bs.buffer = [[0100 0000]]
//                 ^ bs.offset
```

It really does only write 3 bytes to an internal buffer. Then when we write the
`e`
```go
bs.Write(0b1110, 4)
// bs.buffer = [[0101 1100]]
//                      ^ bs.offset
```

and we still have a bit remaining that we can write to. which the
`bitstringwriter` will gladly take care of spanning the gap when we write the `l`.
```go
bs.write(0b10, 2)
// bs.buffer = [[0101 1101] [0000 0000]]
//                            ^ bs.offset
```

## How to Encode Sub-byte elements

Here it is, easy enough right?
```go
func (bs *BitStringWriter) Write(b byte, w int) {
	if w < 1 {
		return
	}
	if bs.offset == 0 || bs.offset >= 8 {
		bs.addByte()
	}

	// do we have enough space for the whole "partial-byte"?
	overflow := bs.offset + w
	if overflow > 8 {
		// 1. write part to existing byte
		numBitsLeft := 8 - bs.offset
		left := b >> (w - numBitsLeft)
		bs.writeToLastByte(left, numBitsLeft)

		// 2. add new byte
		bs.addByte()

		// 3. write overflow to new byte
		numBitsRight := w - numBitsLeft
		right := computeRightByte(b, numBitsRight)
		bs.writeToLastByte(right, numBitsRight)

		return
	}

	bs.writeToLastByte(b, w)
}
```

We can probably make it a bit clearer though. Getting straight into the core
logic, we start by checking to see if writing this width would overflow our
current byte.

```go
// do we have enough space for the whole "partial-byte"?
overflow := bs.offset + w
if overflow > 8 {
```

If that's not the case, let's say we have a fresh byte with 8 bits available,
and we want to write the character `h` 3, then we go straight to the last line and write the bits.

```go
bs.writeToLastByte(0b010, 3)
```

This will expand to the following
```go
bs.buffer[len(bs.buffer)-1] = bs.buffer[len(bs.buffer)-1] | (b << (8 - bs.offset - w))
bs.offset += w
```

So we take our current buffer, which we established is empty, and or it with our value.
```go
// psuedocode
bs.buffer[-1] = 0b0000_0000 | (b << (8 - bs.offset - w))
```

But our buffer is completely empty, so we need to shift our value to the left,
so that it occupies the left bits of our byte. We can figure that out from our
offset
```go
0b010 << (8 - 0 - 3)
```

Why did we shift by that amount
- `8` is the number of bits in a byte, so we move all the way to the left
  ```
  [0000 0000]
   ^
  ```
- `0` is our current offset, if we had an offset, we would want to move to the right by that amount
- `3` is the width of our character so we move back to the right by 3
  ```
  [0000 0000]
     ^
  ```

Now when we do the `or` it will write to the correct location
```
[0000 0000] | [0100 0000] => [0100 0000]
```

Okay so now what if you are spanning two bytes? Let's say we've written `he` so
our buffer looks like this, and our offset is currently 7 after the write of 3
and 4 respectively.
```
[[0101 1100]]
          ^
```

We write what we can to our remaining bits
```go
// figure out the number of bits we have left to work with
numBitsLeft := 8 - bs.offset
// shift our byte so it's only the leftmost bit left in the ones.
left := b >> (w - numBitsLeft)
// Write as usual
bs.writeToLastByte(left, numBitsLeft)
```

```
[[0101 1101]]
          ^
b: 0b10
w: 2
numBitsLeft: 8 - bs.offset(7) => 1
left: 0b1
```

Then we grow the buffer.
```go
bs.addByte()
```
```
[[0101 1101] [0000 0000]]
              ^
```

Then we write whatever is left into the right side. Similarly to how we wrote to
the left.
```go
numBitsRight := w - numBitsLeft
right := computeRightByte(b, numBitsRight)
bs.writeToLastByte(right, numBitsRight)
```

```
[[0101 1101] [0000 0000]]
               ^

numBitsRight: w - numBitsLeft => 1
right: 0b0
```


## Encoding the Tree

