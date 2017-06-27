# Bitcoin Visualizer

> A real-time visualizer for the bitcoin blockchain

This visualization shows the bitcoin blockchain. Recently confirmed blocks are at the top and older ones are at the bottom.

Each rectangle is a single block of many transactions. Bitcoin processes about one block every 10 minutes.

The width of the block represents the number of transactions.

The color represents how close it is to capacity in byte size. Blocks are limited by the bitcoin protocol to 1mb, and many blocks are already very close to that limit, as you can see.


## Instructions

To run the project in development mode:

    gulp

Run tests one time:

    npm run test-once

Run a watcher that rebuilds the test package and runs tests whenever a test file changes:

    npm run test-watch
